#!/bin/bash
# find-scope-gate.sh — Bash ツール用の PreToolUse hook。
# リポジトリルート起点の「全走査」を deny し、ignore を尊重する検索へ誘導する。
#
# 動機（2026-09-15 の実測、artista-vita-flow / Colima + virtiofs）:
#   あるセッションの `find <repo root> -name X -not -path '*/node_modules/*'` が
#   27 分走り続け、その間コンテナ内の `ls` 1 回が 25 秒でタイムアウトした
#   （ホストからは 17ms）。ホストからの `colima ssh -- vmstat` すら 30 秒返らない。
#   CPU idle 94-98% / wa 1-2% で、詰まるのは virtiofs の metadata パスだけ。
#   1 プロセスの全走査が共有 mount を占有し、全セッションを巻き込む。
#
#   リポジトリルートの全エントリ 1,359,550 のうち .worktrees/ が 1,150,247 (85%)、
#   .uv-cache/ 99,030、.venv 93,126。git 管理下の実ファイルは 2,604 件。
#   つまり 522 倍の空振りで、同じ探索が `rg --files` なら 2,007 件 / 40ms で終わる。
#   重いディレクトリはすべて .gitignore 済みなので、ignore を見るツールは最初から安全。
#
# 決定ポリシー:
#   - 増幅要因を持つルート起点の無制限走査 -> deny（書き換え形を提示する）
#   - -prune / -maxdepth で降下を止めている -> fall through
#   - 増幅要因のない小さなリポジトリ       -> fall through
#   - それ以外                              -> fall through（無判定）
#
# allow は一切返さない。PreToolUse の allow は権限プロンプトを短絡するので、
# このフックが素通しさせたコマンドを他の gate（pre-tool-block-destructive.py /
# git-push-gate.sh / terraform-apply-guard.sh）が改めて判定できる状態に保つ。
#
# escape hatch: 本当に全走査が必要なときは CLAUDE_ALLOW_FULL_TREE_SCAN=1 を、
# コマンド前置（`CLAUDE_ALLOW_FULL_TREE_SCAN=1 find ...`）か settings.local.json の
# `env` ブロックで与える。後者は gitignore 対象なので `copier update` を跨いで残る。
#
# 既知の誤検知（いずれも fail-open ではなく余分な deny 側に倒れる）:
#   - grep/rg の検索パターンがリポジトリルートと同一の文字列だと path 候補になる
#   - クォート文字列をシェルとして解釈しないため、同一 segment 内の無関係な
#     `-R` や `--no-ignore` がツールのフラグと見なされ得る

set -uo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$CMD" ] && exit 0

# 早期 bail。トークン境界付きで候補コマンドを含まなければ以降の解析をしない。
printf '%s' "$CMD" |
  grep -qE '(^|[[:space:];&|(])(find|bfs|grep|egrep|rg|ls)([[:space:]]|$)' || exit 0

# 増幅要因。この中のどれかがルート直下にあるときだけ deny する。小さなリポジトリで
# `find . -name x` を止めても得がないので、実際に避けるべき膨張があるかで判定する。
HEAVY_DIRS=(.worktrees .venv node_modules .uv-cache .build target .next .tox)

emit_deny() {
  jq -nc --arg r "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

HEAVY_HIT=""

# ルートが「全走査を止めるべき対象」かを判定する。stat は最大 8 回で、いずれも
# ルート直下しか見ないため mount が詰まっていても 1 階層分で済む。
is_wide_root() {
  local p=$1 rp d

  [ -z "$p" ] && return 1
  case "$p" in -*) return 1 ;; esac

  # ブランチ名と同じ理由でパスにクォートは使えないので、除去して意味が変わる入力はない。
  p=${p//\"/}
  p=${p//\'/}

  # case のパターンとしてのチルダはリテラル一致が目的で、展開させたいわけではない。
  # shellcheck disable=SC2088
  case "$p" in
    "~") p=$HOME ;;
    "~/"*) p=$HOME/${p#\~/} ;;
  esac

  # symlink は解決しない。realpath を呼ぶと mount 上で追加の round trip が増え、
  # 守ろうとしている当のボトルネックをフック自身が踏む。
  case "$p" in
    /*) rp=$p ;;
    . | ./) rp=$PWD ;;
    *) rp=$PWD/$p ;;
  esac
  rp=${rp%/.}
  rp=${rp%/}
  [ -z "$rp" ] && rp=/

  # 増幅要因の有無を問わず常に広いルート。
  case "$rp" in
    / | /workspaces | /Users | /home) HEAVY_HIT="(filesystem root)"; return 0 ;;
  esac
  [ "$rp" = "$HOME" ] && { HEAVY_HIT="(home)"; return 0; }

  # リポジトリルートか worktree ルートか。worktree は .git がファイルなので -e で見る。
  [ -e "$rp/.git" ] || [ -d "$rp/.worktrees" ] || return 1

  for d in "${HEAVY_DIRS[@]}"; do
    if [ -d "$rp/$d" ]; then
      HEAVY_HIT="$d/"
      return 0
    fi
  done
  return 1
}

# CRLF を先に LF へ畳むのは、次の行継続 join が '\' + LF にしか一致しないため。
CMD=${CMD//$'\r'$'\n'/$'\n'}
# 改行直前のバックスラッシュは行継続でコマンド境界ではない。先に join しないと
# 継続行が自分の 'find' トークンを持たず、フラグが一切検査されない。
#
# 分割集合に '(' ')' を入れないのは意図的。find の prune 式は
# `\( -name .venv -o -name .git \) -prune` の形を取るので、括弧で切ると
# `find .` だけの segment が生まれて -prune を見落とし、正しい書き換え形を
# こちらが deny してしまう。サブシェルで囲まれた `( find / )` は同一 segment に
# 残るので、検出漏れにはならない。
SEGMENTS=$(printf '%s' "${CMD//\\$'\n'/ }" | tr ';&|<>\r' '\n')

while IFS= read -r SEG; do
  # 前置の env 代入でもフックの env でも同じ escape hatch が効くようにする。
  case "$SEG" in
    *CLAUDE_ALLOW_FULL_TREE_SCAN=1*) continue ;;
  esac
  [ "${CLAUDE_ALLOW_FULL_TREE_SCAN-0}" = 1 ] && exit 0

  read -ra TOKS <<<"$SEG"
  [ "${#TOKS[@]}" -eq 0 ] && continue

  # ツールの特定。前置 env 代入とラッパを読み飛ばしてから最初の候補を採る。
  TOOL=""
  TOOL_AT=-1
  for ((i = 0; i < ${#TOKS[@]}; i++)); do
    case "${TOKS[$i]}" in
      sudo | time | nohup | setsid | command | env | xargs | nice | ionice) continue ;;
      *=*) continue ;;
      find | */find | bfs | */bfs) TOOL="find"; TOOL_AT=$i; break ;;
      grep | */grep | egrep | */egrep) TOOL="grep"; TOOL_AT=$i; break ;;
      rg | */rg) TOOL="rg"; TOOL_AT=$i; break ;;
      ls | */ls) TOOL="ls"; TOOL_AT=$i; break ;;
      *) break ;;
    esac
  done
  [ "$TOOL_AT" -lt 0 ] && continue

  # ツールごとに「そもそも全走査になり得るか」を判定する。ここで落ちた segment は
  # path 解析まで進まない。
  case "$TOOL" in
    find) ;;
    grep)
      # 束ねられた短オプション（-rn 等）も再帰。
      printf '%s' "$SEG" |
        grep -qE '(^|[[:space:]])(-[[:alnum:]]*[rR][[:alnum:]]*|--recursive|--dereference-recursive)([[:space:]]|$)' ||
        continue
      # --exclude-dir を付けているなら降下を止めているので判定しない。
      printf '%s' "$SEG" | grep -q -- '--exclude-dir' && continue
      ;;
    rg)
      # 既定の rg は .gitignore を尊重するので無害。ignore を切ったときだけ対象。
      printf '%s' "$SEG" |
        grep -qE '(^|[[:space:]])(--no-ignore(-vcs|-dot|-parent|-global)?|-u{1,3})([[:space:]]|$)' ||
        continue
      ;;
    ls)
      printf '%s' "$SEG" |
        grep -qE '(^|[[:space:]])(-[[:alnum:]]*R[[:alnum:]]*|--recursive)([[:space:]]|$)' ||
        continue
      ;;
  esac

  # 降下を実際に止めているかの判定。`-not -path` / `-path` は出力を絞るだけで
  # descent を止めないため限定に数えない — 今回の事故はまさにこれで、
  # `-not -path '*/node_modules/*'` を付けたまま 136 万エントリを stat していた。
  if [ "$TOOL" = find ]; then
    printf '%s' "$SEG" | grep -qE '(^|[[:space:]])-prune([[:space:]]|$)' && continue
    MAXDEPTH=$(printf '%s' "$SEG" |
      grep -oE '(^|[[:space:]])-maxdepth[[:space:]]+[0-9]+' |
      grep -oE '[0-9]+$' | head -1)
    if [ -n "$MAXDEPTH" ] && [ "$MAXDEPTH" -le 3 ]; then
      continue
    fi
  fi

  # path operand の収集。
  PATHS=()
  case "$TOOL" in
    find)
      # GNU find / bfs は path の前にもオプションを取る（-L, -S dfs 等）。
      i=$((TOOL_AT + 1))
      while [ "$i" -lt "${#TOKS[@]}" ]; do
        case "${TOKS[$i]}" in
          -H | -L | -P | -O*) i=$((i + 1)) ;;
          -S | -D | -regextype | --regextype) i=$((i + 2)) ;;
          *) break ;;
        esac
      done
      # path operand は最初の式トークンまで。
      while [ "$i" -lt "${#TOKS[@]}" ]; do
        case "${TOKS[$i]}" in
          -* | '!' | '(' | '\(') break ;;
        esac
        PATHS+=("${TOKS[$i]}")
        i=$((i + 1))
      done
      ;;
    grep | rg)
      # 非フラグトークンのうち先頭は検索パターン。残りが path。パターンだけなら
      # 探索先は cwd。フラグの値（-e PATTERN 等）を厳密に追わないため、余分な
      # path 候補が混じり得るが、倒れる方向は deny 側。
      NONFLAG=()
      for ((i = TOOL_AT + 1; i < ${#TOKS[@]}; i++)); do
        case "${TOKS[$i]}" in
          -*) continue ;;
        esac
        NONFLAG+=("${TOKS[$i]}")
      done
      if [ "${#NONFLAG[@]}" -le 1 ]; then
        PATHS=("$PWD")
      else
        PATHS=("${NONFLAG[@]:1}")
      fi
      ;;
    ls)
      for ((i = TOOL_AT + 1; i < ${#TOKS[@]}; i++)); do
        case "${TOKS[$i]}" in
          -*) continue ;;
        esac
        PATHS+=("${TOKS[$i]}")
      done
      [ "${#PATHS[@]}" -eq 0 ] && PATHS=("$PWD")
      ;;
  esac
  [ "${#PATHS[@]}" -eq 0 ] && PATHS=("$PWD")

  for p in "${PATHS[@]}"; do
    is_wide_root "$p" || continue

    emit_deny "$(
      printf '%s\n' \
        "全走査を止めました: ${TOOL} が ${p} を起点にしていて、降下を止める指定がありません（${HEAVY_HIT} を含むルートです）。" \
        "" \
        "-not -path / -path / --include は出力を絞るだけで descent を止めないので、除外にはなりません。実際に降下を止めるのは -prune と -maxdepth だけです。" \
        "" \
        "書き換え形:" \
        "  rg --files -g '<pattern>'        # .gitignore を尊重。実測 2,007 件 / 40ms" \
        "  rg '<pattern>'                   # 内容検索も既定で ignore を尊重" \
        "  git ls-files '<pattern>'         # tracked のみ" \
        "  find <探索先の分かっているディレクトリ> -name '<pattern>'" \
        "" \
        "gitignore 対象の生成物（ビルド出力・メディア等）を探すなら、降下そのものを止める形にしてください:" \
        "  find ${p} \\( -name .worktrees -o -name .venv -o -name .uv-cache -o -name node_modules -o -name .git \\) -prune -o -name '<pattern>' -print" \
        "" \
        "この mount は virtiofs で、metadata が並列度に対して超線形に劣化します。全走査 1 本で全セッションが数十分止まります。どうしても必要なら CLAUDE_ALLOW_FULL_TREE_SCAN=1 を前置してください。"
    )"
  done
done <<<"$SEGMENTS"

exit 0
