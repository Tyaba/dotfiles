#!/usr/bin/env python3
"""Codex への移譲を Claude Enterprise のセッションに限定する hook。

方針（2026-11-09）:
  Codex オフロードは Claude Enterprise の枠を節約するための仕組みであり、
  Claude Code を Max サブスクリプション・Vertex AI・API キー等で動かしているときは使わない。
  ルール文（user-rules.md）だけでは「どのプランで動いているか」をモデルが知る手段がないため、
  この hook がプランを判定して、起動時の文脈注入と実行時の deny の両方を行う。

モード:
  session-start  SessionStart hook。現在のプランと Codex 移譲の可否を additionalContext で渡す。
  （引数なし）   PreToolUse hook。Enterprise 以外で次の呼び出しを deny する。
                 - Agent / Task: subagent_type が codex-offload / codex:codex-rescue
                 - Skill: codex:rescue
                 - Bash: `codex exec` / `codex e` / `codex review` / `codex resume` の起動

プラン判定:
  1. CLAUDE_CODE_USE_VERTEX / CLAUDE_CODE_USE_BEDROCK が真 -> vertex / bedrock
  2. ANTHROPIC_API_KEY が設定済み -> api（OAuth より優先されるため）
  3. ${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json の oauthAccount.organizationType
     （claude_enterprise / claude_max / ...）。ファイルが数百 KB あるので正規表現で読む
  判定できない場合は「Enterprise ではない」として扱う（許可するのは Enterprise と確認できた時だけ）。

allow は返さない（他の gate の判定を短絡させないため）。
入力 JSON の解析に失敗した場合は何もしない。
"""

from __future__ import annotations

import json
import os
import re
import sys

CODEX_AGENTS = {"codex-offload", "codex:codex-rescue"}
CODEX_SKILLS = {"codex:rescue"}

# 行頭・区切り文字・コマンド置換の直後に現れる `codex <サブコマンド>` を拾う。
# `codex login status` や `codex --version` のような移譲でない操作は対象外。
CODEX_EXEC_RE = re.compile(
    r"(?:^|[;&|(`\n]|\$\()\s*(?:\S+=\S*\s+)*(?:env\s+|timeout\s+\S+\s+)?(?:\S*/)?codex"
    r"\s+(?:-\S+\s+(?:\S+\s+)?)*(?:exec|e|review|resume)\b"
)

PLAN_LABELS = {
    "claude_enterprise": "Claude Enterprise",
    "claude_max": "Claude Max",
    "claude_team": "Claude Team",
    "claude_pro": "Claude Pro",
    "vertex": "Vertex AI",
    "bedrock": "Amazon Bedrock",
    "api": "Anthropic API キー",
    "unknown": "不明",
}


def _truthy(name: str) -> bool:
    return os.environ.get(name, "").strip().lower() not in ("", "0", "false", "no")


def detect_plan() -> str:
    if _truthy("CLAUDE_CODE_USE_VERTEX"):
        return "vertex"
    if _truthy("CLAUDE_CODE_USE_BEDROCK"):
        return "bedrock"
    if os.environ.get("ANTHROPIC_API_KEY"):
        return "api"
    cfg = os.path.join(os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~"), ".claude.json")
    try:
        with open(cfg, encoding="utf-8") as f:
            m = re.search(r'"organizationType"\s*:\s*"([^"]*)"', f.read())
    except OSError:
        return "unknown"
    return m.group(1) if m and m.group(1) else "unknown"


def label(plan: str) -> str:
    return PLAN_LABELS.get(plan, plan)


def session_start(plan: str) -> None:
    if plan == "claude_enterprise":
        msg = (
            f"現在の Claude Code の課金経路: {label(plan)}。"
            "Codex オフロードは有効。user-rules.md の「Codex オフロード」節に従い、"
            "コード変更は codex-offload サブエージェントに移譲する。"
        )
    else:
        msg = (
            f"現在の Claude Code の課金経路: {label(plan)}。"
            "Codex オフロードは Claude Enterprise のときだけ使う方針のため、このセッションでは禁止。"
            "codex-offload / codex:codex-rescue サブエージェントや codex exec を呼ばず、"
            "コード変更は Claude が Edit / Write で直接実装する"
            "（user-rules.md の「Codex オフロード」節の移譲ゲートはこのセッションでは適用しない）。"
        )
    print(
        json.dumps(
            {"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": msg}},
            ensure_ascii=False,
        )
    )


def is_codex_call(data: dict) -> bool:
    tool = data.get("tool_name", "")
    inp = data.get("tool_input") or {}
    if tool in ("Agent", "Task"):
        return inp.get("subagent_type", "") in CODEX_AGENTS
    if tool == "Skill":
        return inp.get("skill", "").lstrip("/") in CODEX_SKILLS
    if tool == "Bash":
        return bool(CODEX_EXEC_RE.search(inp.get("command", "")))
    return False


def pre_tool_use(plan: str) -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return
    if plan == "claude_enterprise" or not is_codex_call(data):
        return
    reason = (
        f"Codex オフロードは Claude Enterprise のときだけ使う方針です（現在: {label(plan)}）。"
        "Codex に移譲せず、Claude が Edit / Write で直接実装してください。"
    )
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            },
            ensure_ascii=False,
        )
    )


def main() -> None:
    plan = detect_plan()
    if len(sys.argv) > 1 and sys.argv[1] == "session-start":
        session_start(plan)
    else:
        pre_tool_use(plan)


if __name__ == "__main__":
    main()
