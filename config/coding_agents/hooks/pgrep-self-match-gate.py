#!/usr/bin/env python3
"""Bash / Monitor ツール用の PreToolUse hook。`pgrep -f` / `pkill -f` を deny する。

動機（2026-10-15）:
  親セッションが codex-offload サブエージェントの完了を待つために
  `for i in $(seq 1 58); do if ! pgrep -f "bin/codex exec" ...; then break; fi; sleep 30; done`
  を run_in_background で回した。Codex 本体は毎回 3〜4 分で終わっていたのに、
  ループは 29 分のタイムアウトまで抜けず、ユーザーが問い合わせるたびに
  「ちょうど終わった」と答える状態が続いた。

  Bash ツールはコマンド全文を `/bin/bash -c '... eval '"'"'<コマンド>'"'"' ...'` の
  argv に載せて実行する。pgrep は自分自身は除外するが親のシェルは除外しないので、
  パターンの文字列がコマンド中に書かれていれば（待機ループでは普通そうなる）
  `pgrep -f` はそのシェルに一致し、常に rc=0 になる。`[c]odex` のようなブラケット技も、
  同じコマンド内のどこかに素の文字列があればそれに一致して無効になる。
  `pkill -f` は同じ理由で自分のシェルを殺す。パターンを `"$PAT"` のように変数で渡せば
  自己一致はしないが、書き方次第で壊れる道具を待機に使わせない方針で一律に deny する。

判定方法:
  正規表現ではなく簡易的なシェル字句解析を行う。
  - クォート内・コメント・heredoc 本文・リダイレクト先は命令として扱わない
  - `$(...)` / バッククォート / `<(...)`（ダブルクォート内のものを含む）は中身を再帰的に解析する
  - `bash -c STR` / `eval STR` / `watch STR` の文字列引数も再帰的に解析する
  - 単純コマンドの先頭にある予約語・変数代入・ラッパ（env / sudo / nice / timeout /
    xargs など）を読み飛ばし、実際に起動されるコマンドが pgrep / pkill かを見る
  - pgrep / pkill のオプションを getopt と同じ規則で読み、-f（束ねた短オプション含む）か
    --full があれば deny

allow は返さない（他の gate の判定を短絡させないため。find-scope-gate.sh と同じ方針）。
解析中に例外が出た場合は何もしない（fail-open。全 Bash 呼び出しを止めないため）。

既知の取りこぼし（fail-open 側）:
  - クォートしていない区切り文字の heredoc 本文に書いた `$(pgrep -f ...)` は実行されるが見ない
  - 未知のラッパや、引数を別の語で取る未知の長オプション（`sudo --user root ...` 等）
  - `ssh host pgrep -f ...` のようなリモート実行（自己一致の問題自体が起きない）
"""

from __future__ import annotations

import json
import os
import re
import sys

TARGETS = {"pgrep", "pkill"}

# 単純コマンドの先頭で読み飛ばす予約語。
RESERVED = {"!", "{", "}", "if", "then", "else", "elif", "fi", "do", "done", "while", "until"}

# ラッパ -> 引数を取る短オプションの集合。ラッパの後ろにある最初の非オプション語を
# 改めてコマンドとして扱う。
WRAPPERS = {
    "builtin": "",
    "chrt": "",
    "command": "",
    "doas": "uC",
    "env": "uCS",
    "exec": "a",
    "ionice": "cnp",
    "nice": "n",
    "nohup": "",
    "setsid": "",
    "stdbuf": "ioe",
    "sudo": "ugCDhprtUT",
    "taskset": "",
    "time": "fo",
    "timeout": "sk",
    "watch": "n",
    "xargs": "IndPELsa",
}
# オプションの後ろに位置引数を 1 つ取るラッパ（timeout DURATION）。
WRAPPER_POSITIONAL = {"timeout": 1}
# 残りの引数を連結して sh -c に渡すラッパ。
STRING_WRAPPERS = {"watch"}
SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}

# pgrep / pkill で引数を取る短オプションと長オプション。
TARGET_ARG_SHORT = "dgGPstuUFrq"
TARGET_ARG_LONG = {
    "--cgroup",
    "--delimiter",
    "--env",
    "--euid",
    "--group",
    "--ns",
    "--nslist",
    "--parent",
    "--pidfile",
    "--queue",
    "--runstates",
    "--session",
    "--signal",
    "--terminal",
    "--uid",
}

ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?\+?=")
REDIR_OPS = ("<<<", "<<-", "&>>", "<<", "&>", ">>", ">&", "<&", "<>", ">|", ">", "<")
CONTROL_OPS = ("&&", "||", ";;", "|&", ";", "&", "|", "(", ")")
MAX_DEPTH = 8


def skip_parens(src: str, i: int) -> int:
    """src[i] == '(' から対応する ')' の直後の位置を返す。クォートは読み飛ばす。"""
    depth = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == "\\":
            i += 2
            continue
        if c == "'":
            j = src.find("'", i + 1)
            i = n if j == -1 else j + 1
            continue
        if c == '"':
            _, i = read_dquote(src, i + 1, [])
            continue
        if c == "`":
            _, i = read_backtick(src, i + 1)
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return n


def read_backtick(src: str, i: int) -> tuple[str, int]:
    """開きバッククォートの直後から、中身と閉じの直後の位置を返す。"""
    out = []
    n = len(src)
    while i < n:
        c = src[i]
        if c == "\\" and i + 1 < n:
            out.append(src[i + 1] if src[i + 1] in "`$\\" else src[i : i + 2])
            i += 2
            continue
        if c == "`":
            return "".join(out), i + 1
        out.append(c)
        i += 1
    return "".join(out), n


def read_dquote(src: str, i: int, nested: list[str]) -> tuple[str, int]:
    """開きダブルクォートの直後から、展開前の文字列と閉じの直後の位置を返す。

    中にあるコマンド置換は実行されるので nested に積む。
    """
    out = []
    n = len(src)
    while i < n:
        c = src[i]
        if c == "\\" and i + 1 < n:
            out.append(src[i + 1] if src[i + 1] in '$`"\\\n' else src[i : i + 2])
            i += 2
            continue
        if c == '"':
            return "".join(out), i + 1
        if src.startswith("$((", i):
            j = skip_parens(src, i + 1)
            out.append(src[i:j])
            i = j
            continue
        if src.startswith("$(", i):
            j = skip_parens(src, i + 1)
            nested.append(src[i + 2 : j - 1])
            out.append("_")
            i = j
            continue
        if c == "`":
            inner, i = read_backtick(src, i + 1)
            nested.append(inner)
            out.append("_")
            continue
        out.append(c)
        i += 1
    return "".join(out), n


def lex(src: str) -> tuple[list[tuple[str, str]], list[str]]:
    """トークン列 [(kind, text)] と、再帰的に解析すべき入れ子のコマンド文字列を返す。

    kind は "w"（クォート除去後の語）/ "op"（制御演算子）/ "redir"（リダイレクト演算子）。
    """
    toks: list[tuple[str, str]] = []
    nested: list[str] = []
    heredocs: list[tuple[str, bool]] = []
    word: str | None = None
    i = 0
    n = len(src)

    def end_word() -> None:
        nonlocal word
        if word is None:
            return
        if toks and toks[-1] == ("redir", "<<"):
            heredocs.append((word, False))
        elif toks and toks[-1] == ("redir", "<<-"):
            heredocs.append((word, True))
        toks.append(("w", word))
        word = None

    while i < n:
        c = src[i]
        if c == "\n":
            end_word()
            toks.append(("op", ";"))
            i += 1
            # 行末で、この行に現れた heredoc の本文を出現順に読み飛ばす。
            for delim, strip_tabs in heredocs:
                while i < n:
                    j = src.find("\n", i)
                    j = n if j == -1 else j
                    line = src[i:j]
                    i = j + 1
                    if strip_tabs:
                        line = line.lstrip("\t")
                    if line == delim:
                        break
            heredocs = []
            continue
        if c in " \t":
            end_word()
            i += 1
            continue
        if c == "#" and word is None:
            j = src.find("\n", i)
            i = n if j == -1 else j
            continue
        if c == "\\":
            if src.startswith("\n", i + 1):
                i += 2
                continue
            word = (word or "") + src[i + 1 : i + 2]
            i += 2
            continue
        if c == "'":
            j = src.find("'", i + 1)
            j = n if j == -1 else j
            word = (word or "") + src[i + 1 : j]
            i = j + 1
            continue
        if c == '"':
            text, i = read_dquote(src, i + 1, nested)
            word = (word or "") + text
            continue
        if c == "`":
            inner, i = read_backtick(src, i + 1)
            nested.append(inner)
            word = (word or "") + "_"
            continue
        if src.startswith("$((", i):
            j = skip_parens(src, i + 1)
            word = (word or "") + src[i:j]
            i = j
            continue
        if src.startswith("$(", i) or (c in "<>" and src.startswith("(", i + 1)):
            j = skip_parens(src, i + 1)
            nested.append(src[i + 2 : j - 1])
            word = (word or "") + "_"
            i = j
            continue
        if c in "<>" or src.startswith("&>", i):
            op = next(o for o in REDIR_OPS if src.startswith(o, i))
            if word is not None and word.isdigit():
                word = None  # `2>` の fd 番号
            else:
                end_word()
            toks.append(("redir", op))
            i += len(op)
            continue
        if c in ";&|()":
            end_word()
            op = next(o for o in CONTROL_OPS if src.startswith(o, i))
            toks.append(("op", op))
            i += len(op)
            continue
        word = (word or "") + c
        i += 1
    end_word()
    return toks, nested


def simple_commands(toks: list[tuple[str, str]]) -> list[list[str]]:
    """制御演算子で区切り、リダイレクトとその対象を除いた語の列を返す。"""
    cmds: list[list[str]] = [[]]
    skip_next = False
    for kind, text in toks:
        if kind == "op":
            cmds.append([])
            skip_next = False
        elif kind == "redir":
            skip_next = True
        elif skip_next:
            skip_next = False
        else:
            cmds[-1].append(text)
    return [c for c in cmds if c]


def skip_options(words: list[str], i: int, arg_short: str) -> int:
    """words[i:] のオプションを読み飛ばし、最初の非オプション語の位置を返す。"""
    while i < len(words):
        w = words[i]
        if w == "--":
            return i + 1
        if not w.startswith("-") or w == "-":
            return i
        i += 1
        if w.startswith("--"):
            continue
        for k, ch in enumerate(w[1:]):
            if ch in arg_short:
                if k == len(w) - 2:
                    i += 1
                break
    return i


def has_full_flag(args: list[str]) -> bool:
    """pgrep / pkill の引数に -f / --full があるか（getopt と同じく位置を問わない）。"""
    j = 0
    while j < len(args):
        a = args[j]
        j += 1
        if a == "--":
            return False
        if a.startswith("--"):
            name = a.split("=", 1)[0]
            if name == "--full":
                return True
            if name in TARGET_ARG_LONG and "=" not in a:
                j += 1
            continue
        if not a.startswith("-") or a == "-":
            continue
        for k, ch in enumerate(a[1:]):
            if ch == "f":
                return True
            if ch in TARGET_ARG_SHORT:
                if k == len(a) - 2:
                    j += 1
                break
    return False


def check_words(words: list[str], depth: int) -> str | None:
    i = 0
    while i < len(words):
        w = words[i]
        if w in RESERVED or ASSIGN_RE.match(w):
            i += 1
            continue
        cmd = os.path.basename(w)
        if cmd in WRAPPERS:
            i = skip_options(words, i + 1, WRAPPERS[cmd])
            i += WRAPPER_POSITIONAL.get(cmd, 0)
            if cmd in STRING_WRAPPERS:
                return analyze(" ".join(words[i:]), depth + 1)
            continue
        if cmd in TARGETS:
            return cmd if has_full_flag(words[i + 1 :]) else None
        if cmd == "eval":
            return analyze(" ".join(words[i + 1 :]), depth + 1)
        if cmd in SHELLS:
            has_c = False
            for a in words[i + 1 :]:
                if a.startswith("-") and not a.startswith("--"):
                    has_c = has_c or "c" in a[1:]
                    continue
                return analyze(a, depth + 1) if has_c else None
        return None
    return None


def analyze(src: str, depth: int = 0) -> str | None:
    """src 中で実行される pgrep -f / pkill -f があればそのコマンド名を返す。"""
    if depth > MAX_DEPTH or ("pgrep" not in src and "pkill" not in src):
        return None
    toks, nested = lex(src)
    for words in simple_commands(toks):
        hit = check_words(words, depth)
        if hit:
            return hit
    for inner in nested:
        hit = analyze(inner, depth + 1)
        if hit:
            return hit
    return None


def main() -> None:
    try:
        data = json.load(sys.stdin)
        cmd = (data.get("tool_input") or {}).get("command") or ""
        hit = analyze(cmd.replace("\r", ""))
    except Exception:  # noqa: BLE001 - 解析失敗で全コマンドを止めない
        return
    if not hit:
        return
    reason = "\n".join(
        [
            f"{hit} -f を止めました: Bash / Monitor ツールはコマンド全文を自分のシェルの argv に載せて実行するため、"
            f"パターンの文字列がコマンドに書かれていると {hit} -f はそのシェル自身に一致します"
            "（pgrep は常に「見つかった」、pkill は自分を殺す）。待機ループに使うと対象が終わっても抜けられません。",
            "",
            "やりたいことに応じて次に置き換えてください:",
            "  - サブエージェント（codex-offload 等）やバックグラウンド Bash の完了待ち: ループを書かない。"
            "完了は自動で通知されるので、ターンを終えて通知を待つ",
            "  - 自分で起動したプロセスの終了待ち: 起動時に $! を記録し、kill -0 <pid> で確認する",
            "  - 一度だけ様子を見る: ps -eo pid,etime,args | grep '[c]odex exec'"
            "（ブラケットで grep 自身を外す。素の文字列を同じコマンドに書かないこと）",
        ]
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
        ensure_ascii=False,
    )


if __name__ == "__main__":
    main()
