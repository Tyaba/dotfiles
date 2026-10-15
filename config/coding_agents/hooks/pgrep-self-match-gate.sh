#!/bin/bash
# pgrep-self-match-gate.sh — Bash ツール用の PreToolUse hook。
# `pgrep -f` / `pkill -f`（コマンドライン全体への部分一致）を deny する。
#
# 動機（2026-10-15、artista-vita-zwei の TDD セッション）:
#   親セッションが codex-offload サブエージェントの完了を待つために
#   `for i in $(seq 1 58); do if ! pgrep -f "bin/codex exec" ...; then break; fi; sleep 30; done`
#   を run_in_background で回した。Codex 本体は毎回 3〜4 分で終わっていたのに、
#   ループは 29 分のタイムアウトまで抜けず、ユーザーが問い合わせるたびに
#   「ちょうど終わった」と答える状態が続いた。
#
#   Bash ツールはコマンド全文を `/bin/bash -c '... eval '"'"'<コマンド>'"'"' ...'` の
#   argv に載せて実行する。pgrep は自分自身は除外するが親のシェルは除外しないので、
#   `pgrep -f X` は X が何であってもそのシェルに一致し、常に rc=0 になる。
#   `[c]odex` のようなブラケット技も、同じコマンド内のどこかに素の文字列があれば
#   それに一致して無効になる。`pkill -f X` は自分のシェルを殺す。
#   つまり Bash ツールの中では pgrep -f / pkill -f は原理的に正しく動かない。
#
# 決定ポリシー:
#   - コマンド位置にある pgrep / pkill に -f（束ねた短オプション含む）か --full -> deny
#   - それ以外                                                              -> fall through
#
# allow は返さない（他の gate の判定を短絡させないため。find-scope-gate.sh と同じ方針）。
#
# 既知の取りこぼし（fail-open 側）:
#   - `bash -c 'pgrep -f ...'` のようにクォート内に入ったものは見ない
#   - heredoc 本文は解析対象から外す（ドキュメントやスクリプトの書き出しを止めないため）

set -uo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$CMD" ] && exit 0

# 早期脱出。全 Bash 呼び出しで走るので、該当語が無ければ何もしない。
case "$CMD" in
  *pgrep* | *pkill*) ;;
  *) exit 0 ;;
esac

# heredoc の開始。`<<<`（herestring）を巻き込まないよう直前の '<' を除外する。
HEREDOC_RE='(^|[^<])<<-?[[:space:]]*["'"'"']?([A-Za-z_][A-Za-z0-9_]*)'

# コマンド位置の pgrep / pkill と、同じ単純コマンド内の -f / --full。
# 直前に許すのは行頭・コマンド区切り・コマンド置換の開始・制御構文のキーワード・
# 一般的なラッパだけ。`grep "pgrep -f" file` のようにクォート内に現れる語は拾わない。
LEAD='(^|[;&|(`!{]|(^|[[:space:]])(then|do|else|if|while|until|sudo|nohup|time|timeout[[:space:]]+[^[:space:]]+|watch|xargs|exec|command))'
CMD_RE="${LEAD}[[:space:]]*([^[:space:];&|()]*/)?(pgrep|pkill)([[:space:]]+[^;&|()]*)?[[:space:]](-[[:alnum:]]*f[[:alnum:]]*|--full)([[:space:]=]|$)"

delim=""
body=0
hit=""
CMD=${CMD//$'\r'/}
# 行継続は先に join する（下の here-string）。継続行に分かれた -f を見落とさないため。
while IFS= read -r line; do
  if [ "$body" = 1 ]; then
    head=${line#"${line%%[![:space:]]*}"}
    [ "${head%%[[:space:]]*}" = "$delim" ] && body=0
    continue
  fi
  if [[ $line =~ $CMD_RE ]]; then
    hit=${BASH_REMATCH[5]}
    break
  fi
  if [[ $line =~ $HEREDOC_RE ]]; then
    delim=${BASH_REMATCH[2]}
    body=1
  fi
done <<<"${CMD//\\$'\n'/ }"

[ -z "$hit" ] && exit 0

reason=$(
  printf '%s\n' \
    "${hit} -f を止めました: Bash ツールはコマンド全文を自分のシェルの argv に載せて実行するため、${hit} -f はどのパターンでもそのシェル自身に一致します（pgrep は常に「見つかった」、pkill は自分を殺す）。待機ループに使うと対象が終わっても抜けられません。" \
    "" \
    "やりたいことに応じて次に置き換えてください:" \
    "  - サブエージェント（codex-offload 等）やバックグラウンド Bash の完了待ち: ループを書かない。完了は自動で通知されるので、ターンを終えて通知を待つ" \
    "  - 自分で起動したプロセスの終了待ち: 起動時に \$! を記録し、kill -0 <pid> で確認する（必要なら Monitor ツールの until 条件に使う）" \
    "  - 一度だけ様子を見る: ps -eo pid,etime,args | grep '[c]odex exec'（ブラケットで grep 自身を外す。素の文字列を同じコマンドに書かないこと）"
)

jq -nc --arg r "$reason" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
exit 0
