"""codex-offload-plan-gate.py の動作テスト。

一時ディレクトリに置いたダミーの .claude.json を CLAUDE_CONFIG_DIR で読ませて検査する。
実行: python3 -I config/coding_agents/hooks/codex-offload-plan-gate.test.py
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

HOOK = str(Path(__file__).with_name("codex-offload-plan-gate.py"))
tmp = Path(tempfile.mkdtemp())


def config_dir(org: str | None) -> str:
    d = tmp / (org or "none")
    d.mkdir(exist_ok=True)
    if org is not None:
        (d / ".claude.json").write_text(json.dumps({"oauthAccount": {"organizationType": org}}, indent=2))
    return str(d)


BASE_ENV = {
    k: v
    for k, v in os.environ.items()
    if k not in ("CLAUDE_CODE_USE_VERTEX", "CLAUDE_CODE_USE_BEDROCK", "ANTHROPIC_API_KEY")
}


def run(payload: dict | None, org: str | None, extra_env: dict | None = None, mode: str | None = None) -> str:
    env = dict(BASE_ENV, CLAUDE_CONFIG_DIR=config_dir(org), **(extra_env or {}))
    argv = [sys.executable, HOOK] + ([mode] if mode else [])
    r = subprocess.run(argv, check=False, input=json.dumps(payload or {}), capture_output=True, text=True, env=env)
    assert r.returncode == 0, r.stderr
    return r.stdout


def decision(payload: dict, org: str | None, extra_env: dict | None = None) -> str:
    return "deny" if '"deny"' in run(payload, org, extra_env) else "pass"


def agent(t: str) -> dict:
    return {"tool_name": "Agent", "tool_input": {"subagent_type": t}}


def bash(cmd: str) -> dict:
    return {"tool_name": "Bash", "tool_input": {"command": cmd}}


cases = []


def case(name: str, got: str, want: str) -> None:
    cases.append((name, got == want))
    print(f"{'OK  ' if got == want else 'FAIL'} {name} want={want} got={got}")


# Max では Codex 呼び出しを deny する
case("max agent codex-offload", decision(agent("codex-offload"), "claude_max"), "deny")
case(
    "max task codex-offload",
    decision({"tool_name": "Task", "tool_input": {"subagent_type": "codex-offload"}}, "claude_max"),
    "deny",
)
case("max agent codex-rescue", decision(agent("codex:codex-rescue"), "claude_max"), "deny")
case(
    "max skill codex:rescue",
    decision({"tool_name": "Skill", "tool_input": {"skill": "codex:rescue"}}, "claude_max"),
    "deny",
)
case("max codex exec", decision(bash('codex exec --json -o /tmp/x "hi" </dev/null'), "claude_max"), "deny")
case(
    "max codex exec with -C and env", decision(bash("cd /a && CODEX_HOME=x codex -C /a exec hi"), "claude_max"), "deny"
)
case("max codex exec resume", decision(bash('codex exec resume --last "more" </dev/null'), "claude_max"), "deny")
case("max absolute path codex review", decision(bash("/usr/local/bin/codex review"), "claude_max"), "deny")

# 移譲でない操作は通す
case("max agent Explore", decision(agent("Explore"), "claude_max"), "pass")
case("max codex login status", decision(bash("codex login status"), "claude_max"), "pass")
case("max codex --version", decision(bash("codex --version"), "claude_max"), "pass")
case("max grep codex exec", decision(bash("grep -n 'codex exec' README.md"), "claude_max"), "pass")
case("max other skill", decision({"tool_name": "Skill", "tool_input": {"skill": "simplify"}}, "claude_max"), "pass")

# Enterprise では通す
case("enterprise agent codex-offload", decision(agent("codex-offload"), "claude_enterprise"), "pass")
case("enterprise codex exec", decision(bash("codex exec hi </dev/null"), "claude_enterprise"), "pass")

# Enterprise の OAuth でも Vertex / Bedrock / API キーが優先されれば deny
case(
    "enterprise + vertex",
    decision(agent("codex-offload"), "claude_enterprise", {"CLAUDE_CODE_USE_VERTEX": "1"}),
    "deny",
)
case(
    "enterprise + bedrock",
    decision(agent("codex-offload"), "claude_enterprise", {"CLAUDE_CODE_USE_BEDROCK": "true"}),
    "deny",
)
case(
    "enterprise + api key",
    decision(agent("codex-offload"), "claude_enterprise", {"ANTHROPIC_API_KEY": "sk-dummy"}),
    "deny",
)
case(
    "enterprise + vertex=0",
    decision(agent("codex-offload"), "claude_enterprise", {"CLAUDE_CODE_USE_VERTEX": "0"}),
    "pass",
)

# 判定できない場合は禁止側に倒す
case("no .claude.json", decision(agent("codex-offload"), None), "deny")

# 不正な入力では何もしない
env = dict(BASE_ENV, CLAUDE_CONFIG_DIR=config_dir("claude_max"))
r = subprocess.run([sys.executable, HOOK], check=False, input="not json", capture_output=True, text=True, env=env)
case("invalid json", "pass" if r.returncode == 0 and not r.stdout else "error", "pass")

# SessionStart の文脈注入
out = json.loads(run(None, "claude_max", mode="session-start"))["hookSpecificOutput"]
case(
    "session-start max",
    "禁止" if "禁止" in out["additionalContext"] and "Claude Max" in out["additionalContext"] else "other",
    "禁止",
)
out = json.loads(run(None, "claude_enterprise", mode="session-start"))["hookSpecificOutput"]
case("session-start enterprise", "有効" if "有効" in out["additionalContext"] else "other", "有効")
out = json.loads(run(None, "claude_enterprise", {"CLAUDE_CODE_USE_VERTEX": "1"}, mode="session-start"))[
    "hookSpecificOutput"
]
case(
    "session-start vertex",
    "禁止" if "Vertex AI" in out["additionalContext"] and "禁止" in out["additionalContext"] else "other",
    "禁止",
)

passed = sum(ok for _, ok in cases)
print(f"{passed}/{len(cases)} passed")
sys.exit(0 if passed == len(cases) else 1)
