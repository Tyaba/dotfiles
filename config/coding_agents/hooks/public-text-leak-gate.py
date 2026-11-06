#!/usr/bin/env python3
"""Bash ツール用の PreToolUse hook。公開先へ出るテキストに個人識別子・秘密が含まれていれば deny する。

動機（2026-11-06）:
  public リポジトリの PR 本文に、未コミット差分を説明するつもりでホームディレクトリの
  絶対パス（ログインユーザー名入り）をそのまま書いた。差分そのものは除外していたが、
  説明文は検査の対象外だった。GitHub は PR 本文の編集履歴を残すため、後から本文を
  直しても旧版が閲覧できる。出る前に止めるしかない。

検査する操作と対象:
  - gh pr / issue / release / gist / api / repo / discussion / label:
      --title / --body / --notes / --message / --description 等の値、
      --body-file / --notes-file / --input / `-f key=@file` が指すファイル、heredoc 本文
  - git commit: -m / -F の値、heredoc 本文、staged 差分の追加行（-a / --all 時は
      作業ツリーの追加行）
  - git push: リモートに無いコミットのメッセージ・author / committer・差分の追加行
  - git tag -m / -F: メッセージ

  コマンド文字列全体は検査しない。`cd <ホーム配下のパス> && gh pr create ...` の
  パス部分のように、ローカルでしか使われない文字列で誤検知するため。

検出する識別子:
  - ログインユーザー名（vscode / root 等の汎用名は除く）
  - gcloud の固定構成（DOTFILES_GCLOUD_CONFIGURATION、既定 `good`）の account と
    そのローカル部、project ID。devcontainer でも ~/.config/gcloud が mount されて
    いるので同じ値が引ける
  - ~/.config/leak-gate/denylist に 1 行 1 語で書いた追加の語（`#` 始まりはコメント、
    `re:` 始まりは正規表現）。リポジトリには置かない
  - 既知形式の秘密: GitHub / Slack / Google / AWS / Anthropic / OpenAI のトークン、
    PEM 秘密鍵

判定:
  検出したら deny。allow は返さない（他の gate を短絡させないため）。
  モデル側の回避手段（環境変数など）は用意しない。誤検知なら理由を添えて
  ユーザーに `!` での実行を依頼する。
  解析中の例外は検査対象をコマンド全体に広げて続行する（fail-closed 寄り）。
  git の実行に失敗した場合はその対象だけ検査を省く。

既知の取りこぼし:
  - "$BODY" のように変数で渡した本文（展開後の値は hook から見えない）
  - Bash ツールを経由しない公開（Codex の git push、MCP 経由の投稿など）
"""

from __future__ import annotations

import configparser
import getpass
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

GENERIC_USERS = {
    "root", "vscode", "node", "runner", "ubuntu", "user", "codespace", "dev", "admin",
}

SECRET_PATTERNS = [
    ("GitHub トークン", r"\b(?:gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,})"),
    ("Slack トークン", r"\bxox[abposr]-[A-Za-z0-9-]{10,}"),
    ("Google API キー", r"\bAIza[0-9A-Za-z_\-]{35}"),
    ("AWS アクセスキー", r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b"),
    ("Anthropic API キー", r"\bsk-ant-[A-Za-z0-9_\-]{20,}"),
    ("OpenAI API キー", r"\bsk-(?:proj-)?[A-Za-z0-9_\-]{32,}"),
    ("秘密鍵", r"-----BEGIN (?:[A-Z]+ )?PRIVATE KEY-----"),
]

GH_PUBLISH_SUBCOMMANDS = {"pr", "issue", "release", "gist", "api", "repo", "discussion", "label"}
GH_TEXT_FLAGS = {
    "--title", "-t", "--body", "-b", "--notes", "-n", "--message", "-m",
    "--description", "--subject",
}
GH_FILE_FLAGS = {"--body-file", "--notes-file", "--input"}
GIT_MSG_FLAGS = {"-m", "--message"}
GIT_FILE_FLAGS = {"-F", "--file"}

HEREDOC_RE = re.compile(r"(?<!<)<<(?!<)(-?)[ \t]*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2")


# ---------------------------------------------------------------- 識別子の収集

def _word_pattern(word: str) -> str:
    return r"(?<![A-Za-z0-9])" + re.escape(word) + r"(?![A-Za-z0-9])"


def collect_patterns() -> list[tuple[str, re.Pattern[str]]]:
    words: list[tuple[str, str]] = []

    try:
        user = os.environ.get("USER") or getpass.getuser()
    except Exception:
        user = ""
    if user and user.lower() not in GENERIC_USERS and len(user) >= 3:
        words.append(("ログインユーザー名", user))

    gcloud_dir = Path(os.environ.get("CLOUDSDK_CONFIG") or Path.home() / ".config" / "gcloud")
    conf_name = os.environ.get("DOTFILES_GCLOUD_CONFIGURATION", "").strip() or "good"
    conf_file = gcloud_dir / "configurations" / f"config_{conf_name}"
    if conf_file.is_file():
        cp = configparser.ConfigParser()
        try:
            cp.read(conf_file)
            account = cp.get("core", "account", fallback="").strip()
            project = cp.get("core", "project", fallback="").strip()
        except Exception:
            account = project = ""
        if account:
            words.append(("gcloud アカウント", account))
            local = account.split("@", 1)[0]
            if len(local) >= 3 and local.lower() not in GENERIC_USERS:
                words.append(("gcloud アカウント名", local))
        if project:
            words.append(("GCP project ID", project))

    patterns: list[tuple[str, re.Pattern[str]]] = []
    seen: set[str] = set()
    for label, w in words:
        if w.lower() in seen:
            continue
        seen.add(w.lower())
        patterns.append((label, re.compile(_word_pattern(w), re.IGNORECASE)))

    denylist = Path(os.environ.get("LEAK_GATE_DENYLIST") or Path.home() / ".config" / "leak-gate" / "denylist")
    if denylist.is_file():
        for line in denylist.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            try:
                if line.startswith("re:"):
                    patterns.append(("denylist", re.compile(line[3:], re.IGNORECASE)))
                elif len(line) >= 3:
                    patterns.append(("denylist", re.compile(_word_pattern(line), re.IGNORECASE)))
            except re.error:
                continue

    for label, rx in SECRET_PATTERNS:
        patterns.append((label, re.compile(rx)))
    return patterns


# ---------------------------------------------------------------- コマンド解析

def split_heredocs(cmd: str) -> tuple[str, list[str]]:
    """heredoc 本文を取り出し、本文を除いたコマンドと本文のリストを返す。"""
    lines = cmd.split("\n")
    out: list[str] = []
    bodies: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        i += 1
        for m in HEREDOC_RE.finditer(line):
            strip_tabs, delim = m.group(1) == "-", m.group(3)
            body: list[str] = []
            while i < len(lines):
                cur = lines[i].lstrip("\t") if strip_tabs else lines[i]
                i += 1
                if cur == delim:
                    break
                body.append(lines[i - 1])
            bodies.append("\n".join(body))
    return "\n".join(out), bodies


def tokenize(cmd: str) -> list[list[str]]:
    """シェル演算子で区切った単純コマンドごとのトークン列を返す。"""
    ops = ";&|()<>\n"
    lex = shlex.shlex(cmd.replace("\\\n", " "), posix=True, punctuation_chars=ops)
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    lex.commenters = "#"
    commands: list[list[str]] = [[]]
    for tok in lex:
        if tok and all(c in ops for c in tok):
            commands.append([])
        else:
            commands[-1].append(tok)
    return [c for c in commands if c]


def flag_values(args: list[str], flags: set[str]) -> list[str]:
    """`--flag v` / `--flag=v` / `-fv` 形式の値を集める。"""
    vals: list[str] = []
    i = 0
    while i < len(args):
        a = args[i]
        if a in flags and i + 1 < len(args):
            vals.append(args[i + 1])
            i += 2
            continue
        if a.startswith("--") and "=" in a and a.split("=", 1)[0] in flags:
            vals.append(a.split("=", 1)[1])
        elif re.fullmatch(r"-[A-Za-z].+", a):
            # getopt と同じく束ねた短オプション（`-am msg` / `-ammsg`）の中で
            # 値を取るフラグを探し、残りの文字かその次の引数を値とする
            for j in range(1, len(a)):
                if "-" + a[j] in flags:
                    if j + 1 < len(a):
                        vals.append(a[j + 1:])
                    elif i + 1 < len(args):
                        vals.append(args[i + 1])
                        i += 1
                    break
        i += 1
    return vals


def read_file(path: str, cwd: str) -> str:
    if path in ("-", ""):
        return ""
    p = Path(os.path.expanduser(path))
    if not p.is_absolute():
        p = Path(cwd) / p
    try:
        return p.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def git(cwd: str, *args: str) -> str:
    try:
        r = subprocess.run(
            ["git", "-C", cwd, *args], capture_output=True, text=True, timeout=20,
        )
    except Exception:
        return ""
    return r.stdout if r.returncode == 0 else ""


def added_lines(diff: str) -> str:
    keep = []
    for line in diff.splitlines():
        if line.startswith("+") and not line.startswith("+++"):
            keep.append(line[1:])
        elif line.startswith("diff --git") or line.startswith("rename to"):
            keep.append(line)  # パスに識別子が入る場合も検出する
    return "\n".join(keep)


def git_global_opts(toks: list[str], cwd: str) -> tuple[str, int]:
    """`git -C dir -c k=v sub ...` の -C を解決し、サブコマンドの位置を返す。"""
    i = 1
    while i < len(toks):
        t = toks[i]
        if t == "-C" and i + 1 < len(toks):
            cwd = str(Path(cwd) / os.path.expanduser(toks[i + 1]))
            i += 2
        elif t in ("-c", "--git-dir", "--work-tree", "--namespace") and i + 1 < len(toks):
            i += 2
        elif t.startswith("-"):
            i += 1
        else:
            return cwd, i
    return cwd, i


def push_sources(args: list[str]) -> list[str]:
    positionals = []
    skip = False
    for a in args:
        if skip:
            skip = False
            continue
        if a in ("-o", "--push-option", "--repo", "--receive-pack", "--exec"):
            skip = True
            continue
        if a.startswith("-"):
            continue
        positionals.append(a)
    if len(positionals) <= 1:
        return ["HEAD"]
    srcs = []
    for rs in positionals[1:]:
        src = rs.lstrip("+").split(":", 1)[0]
        if src:
            srcs.append(src)
    return srcs or ["HEAD"]


def collect_targets(cmd: str, cwd: str) -> list[tuple[str, str]]:
    """(検査対象の説明, テキスト) のリスト。公開操作を含まなければ空。"""
    rest, heredocs = split_heredocs(cmd)
    targets: list[tuple[str, str]] = []
    publishes = False

    for toks in tokenize(rest):
        # 先頭の変数代入と env / command 等のラッパを飛ばす
        while toks and (re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=.*", toks[0]) or toks[0] in ("env", "command", "builtin", "exec", "time", "nohup")):
            toks = toks[1:]
        if not toks:
            continue
        if toks[0] == "cd" and len(toks) >= 2:
            cwd = str(Path(cwd) / os.path.expanduser(toks[1]))
            continue
        name = os.path.basename(toks[0])

        if name == "gh" and len(toks) >= 2 and toks[1] in GH_PUBLISH_SUBCOMMANDS:
            publishes = True
            args = toks[2:]
            for v in flag_values(args, GH_TEXT_FLAGS):
                targets.append((f"gh {toks[1]} の引数", v))
            file_flags = set(GH_FILE_FLAGS)
            if toks[1] != "api":
                file_flags |= {"-F"}  # pr/issue の -F は --body-file
            for v in flag_values(args, file_flags):
                targets.append((f"gh {toks[1]} の本文ファイル", read_file(v, cwd)))
            if toks[1] == "api":
                for v in flag_values(args, {"-f", "-F", "--field", "--raw-field"}):
                    _, _, val = v.partition("=")
                    if val.startswith("@"):
                        targets.append(("gh api のフィールドファイル", read_file(val[1:], cwd)))
                    else:
                        targets.append(("gh api のフィールド", val))
            continue

        if name == "git":
            gcwd, si = git_global_opts(toks, cwd)
            if si >= len(toks):
                continue
            sub, args = toks[si], toks[si + 1:]
            if sub in ("commit", "tag"):
                publishes = True
                for v in flag_values(args, GIT_MSG_FLAGS):
                    targets.append((f"git {sub} のメッセージ", v))
                for v in flag_values(args, GIT_FILE_FLAGS):
                    targets.append((f"git {sub} のメッセージファイル", read_file(v, gcwd)))
                if sub == "commit":
                    if any(a in ("-a", "--all") or re.fullmatch(r"-[A-Za-z]*a[A-Za-z]*", a) for a in args):
                        diff = git(gcwd, "diff", "HEAD", "--no-color", "--no-ext-diff")
                    else:
                        diff = git(gcwd, "diff", "--cached", "--no-color", "--no-ext-diff")
                    targets.append(("コミットする差分の追加行", added_lines(diff)))
            elif sub == "push":
                publishes = True
                for src in push_sources(args):
                    log = git(
                        gcwd, "log", src, "--not", "--remotes", "--no-color", "--no-ext-diff",
                        "-p", "--format=%x00COMMIT %h%n%an <%ae>%n%cn <%ce>%n%B",
                    )
                    for chunk in log.split("\x00COMMIT ")[1:]:
                        sha, _, body = chunk.partition("\n")
                        head, sep, diff = body.partition("\ndiff --git")
                        text = head + ("\n" + added_lines("diff --git" + diff) if sep else "")
                        targets.append((f"push するコミット {sha}", text))

    if publishes:
        for b in heredocs:
            targets.append(("heredoc 本文", b))
    return targets


# ---------------------------------------------------------------- 本体

def mask(s: str) -> str:
    return s[:2] + "*" * max(len(s) - 2, 1) if len(s) > 2 else "*" * len(s)


def scan(targets: list[tuple[str, str]], patterns) -> list[str]:
    hits: list[str] = []
    for where, text in targets:
        if not text:
            continue
        for label, rx in patterns:
            m = rx.search(text)
            if m:
                hits.append(f"- {where}: {label}（{mask(m.group(0))}）")
    return hits


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    if data.get("tool_name") != "Bash":
        return
    cmd = (data.get("tool_input") or {}).get("command") or ""
    if not re.search(r"\b(gh|git)\b", cmd):
        return
    cwd = data.get("cwd") or os.getcwd()

    try:
        targets = collect_targets(cmd, cwd)
    except Exception:
        if not re.search(r"\bgh\s+(" + "|".join(GH_PUBLISH_SUBCOMMANDS) + r")\b|\bgit\b.*\b(commit|push|tag)\b", cmd):
            return
        targets = [("コマンド全体（解析失敗のため）", cmd)]
    if not targets:
        return

    hits = scan(targets, collect_patterns())
    if not hits:
        return

    reason = (
        "公開先に出るテキストに個人識別子または秘密が含まれています。public リポジトリでは"
        "PR / Issue の本文は編集履歴に残り、push したコミットも消せません。\n"
        + "\n".join(dict.fromkeys(hits))
        + "\n\n該当箇所を削除するか `~` / `<user>` 等のプレースホルダに置き換えてから再実行してください。"
        "コミット済みなら push 前に履歴を書き換えてください。"
        "誤検知だと判断した場合は、理由を説明してユーザーに `!` での実行を依頼してください。"
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
