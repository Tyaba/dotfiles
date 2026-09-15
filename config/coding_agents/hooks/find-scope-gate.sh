#!/bin/bash
# find-scope-gate.sh — Bash ツール用の PreToolUse hook。
# リポジトリルート起点の「全走査」を deny し、ignore を尊重する検索へ誘導する。
#
# 動機（2026-09-15 の実測、Colima + virtiofs の bind mount 上の devcontainer）:
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
#   - 増幅要因を持つルート起点の無制限走査   -> deny（書き換え形を提示する）
#   - -prune / 浅い深さ制限で降下を止めている -> fall through
#   - 増幅要因のない小さなリポジトリ          -> fall through
#   - それ以外                                -> fall through（無判定）
#
# allow は一切返さない。PreToolUse の allow は権限プロンプトを短絡するので、
# このフックが素通しさせたコマンドを他の gate（pre-tool-block-destructive.py /
# git-push-gate.sh / terraform-apply-guard.sh）が改めて判定できる状態に保つ。
#
# escape hatch: 本当に全走査が必要なときは CLAUDE_ALLOW_FULL_TREE_SCAN=1 を、
# コマンド前置（`CLAUDE_ALLOW_FULL_TREE_SCAN=1 find ...`）か settings.local.json の
# `env` ブロックで与える。後者は gitignore 対象なので `copier update` を跨いで残る。
# 前置形は「先頭の env 代入トークン」としてのみ認める。segment 全体の部分一致で
# 見ると、この名前を検索パターンに書くだけでゲートが外れてしまう。
#
# 既知の取りこぼし（いずれも fail-open 側で、余分な deny にはならない）:
#   - 検索パターンが実在ディレクトリと同名だと、それを探索先と見なして cwd 起点の
#     走査を見落とす（例: `rg --no-ignore src`）
#   - `rg --no-ignore -f patterns.txt` のようにパターンをファイルから読む形は、
#     実在ファイルの operand があるため「明示ファイルを読むだけ」と判定される
#   - `bash -c 'find ...'` のようにサブシェル起動を挟むと解析しない
#     （他の gate と共通の穴なので、ここだけ塞いでも意味がない）
#   - heredoc 本文は解析対象から外す（strip_heredocs の理由を参照）

set -uo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$CMD" ] && exit 0

# フック env 経由の escape hatch。segment を見るより前に効かせる。
[ "${CLAUDE_ALLOW_FULL_TREE_SCAN-0}" = 1 ] && exit 0

# 増幅要因。この中のどれかがルート直下にあるときだけ deny する。小さなリポジトリで
# `find . -name x` を止めても得がないので、実際に避けるべき膨張があるかで判定する。
HEAVY_DIRS=(.worktrees .venv node_modules .uv-cache .build target .next .tox)

# 解析対象になり得るコマンド。ここに 1 つも当たらなければ以降の解析をしない。
CANDIDATE_RE='(^|[[:space:];&|(])(find|bfs|grep|egrep|rg|fd|fdfind|ls|tree)([[:space:]]|$)'
# 束ねられた短オプション（-rn 等）も再帰。
GREP_RECURSIVE_RE='(^|[[:space:]])(-[[:alnum:]]*[rR][[:alnum:]]*|--recursive|--dereference-recursive)([[:space:]]|$)'
# 既定の rg / fd は .gitignore を尊重するので無害。ignore を切ったときだけ対象。
RG_UNRESTRICTED_RE='(^|[[:space:]])(--no-ignore(-vcs|-dot|-parent|-global)?|--unrestricted|-u{1,3})([[:space:]]|$)'
FD_UNRESTRICTED_RE='(^|[[:space:]])(--no-ignore(-vcs)?|--unrestricted|-u{1,3}|-I)([[:space:]]|$)'
LS_RECURSIVE_RE='(^|[[:space:]])(-[[:alnum:]]*R[[:alnum:]]*|--recursive)([[:space:]]|$)'
PRUNE_RE='(^|[[:space:]])-prune([[:space:]]|$)'
# heredoc の開始。`<<<`（herestring）を巻き込まないよう直前の '<' を除外する。
HEREDOC_RE='(^|[^<])<<-?[[:space:]]*["'"'"']?([A-Za-z_][A-Za-z0-9_]*)'

emit_deny() {
  jq -nc --arg r "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

STRIPPED=""

# トークンからクォートを外し、先頭の ~ を展開する。戻り値を $STRIPPED に置くのは
# サブシェルを避けるため（このフックは全 Bash 呼び出しで走るので fork を削る）。
strip_token() {
  local t=$1

  # ブランチ名と同じ理由でパスにクォートは使えないので、除去して意味が変わる入力はない。
  t=${t//\"/}
  t=${t//\'/}

  # case のパターンとしてのチルダはリテラル一致が目的で、展開させたいわけではない。
  # shellcheck disable=SC2088
  case "$t" in
    "~") t=$HOME ;;
    "~/"*) t=$HOME/${t#\~/} ;;
  esac

  STRIPPED=$t
}

HEAVY_HIT=""

# ルートが「全走査を止めるべき対象」かを判定する。stat は最大 8 回で、いずれも
# ルート直下しか見ないため mount が詰まっていても 1 階層分で済む。
is_wide_root() {
  local p=$1 rp d

  HEAVY_HIT=""
  [ -z "$p" ] && return 1
  case "$p" in -*) return 1 ;; esac

  strip_token "$p"
  p=$STRIPPED

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

# 浅い深さ制限があるかを見る。降下そのものを止める指定だけを limiter に数える。
depth_limited() {
  local seg=$1 re
  re="(^|[[:space:]])($2)([[:space:]]+|=)([0-9]+)"
  [[ $seg =~ $re ]] || return 1
  [ "${BASH_REMATCH[4]}" -le 3 ]
}

# heredoc 本文はコマンドではない。`<<` の終端ワードまでを解析対象から外す。
# 先に落とさないと、'<' が segment 分割子なので本文の各行が独立したコマンドとして
# 解析され、find の例文を含むファイルを書き出す操作まで deny してしまう
# （このスクリプト自身がその例文を持っている）。
strip_heredocs() {
  local line delim="" body=0 out="" head

  while IFS= read -r line; do
    if [ "$body" = 1 ]; then
      # 終端ワードは前後の空白を許す（`<<-` のタブ字下げを含む）。
      head=${line#"${line%%[![:space:]]*}"}
      [ "${head%%[[:space:]]*}" = "$delim" ] && body=0
      continue
    fi
    out+=$line$'\n'
    if [[ $line =~ $HEREDOC_RE ]]; then
      delim=${BASH_REMATCH[2]}
      body=1
    fi
  done
  printf '%s' "$out"
}

# ';&|<>' をコマンド境界として segment に割る。ただしクォートの内側では割らない。
# `grep -rE 'a|b' src/` の '|' を境界にするとコマンドが途中で切れ、path operand を
# 見失って cwd 起点と誤判定し、無関係な検索まで deny してしまう。
#
# 分割集合に '(' ')' を入れないのは意図的。find の prune 式は
# `\( -name .venv -o -name .git \) -prune` の形を取るので、括弧で切ると
# `find .` だけの segment が生まれて -prune を見落とし、正しい書き換え形を
# こちらが deny してしまう。サブシェルで囲まれた `( find / )` は同一 segment に
# 残るので、検出漏れにはならない。
split_segments() {
  local s=$1 i c q="" out=""

  # 異常に長い入力はクォート追跡を諦めて素朴に割る（bash のループは 1 文字ずつ）。
  if [ "${#s}" -gt 16384 ]; then
    printf '%s' "$s" | tr ';&|<>' '\n'
    return
  fi

  for ((i = 0; i < ${#s}; i++)); do
    c=${s:i:1}
    if [ -n "$q" ]; then
      [ "$c" = "$q" ] && q=""
      out+=$c
      continue
    fi
    case "$c" in
      "'" | '"') q=$c; out+=$c ;;
      ';' | '&' | '|' | '<' | '>') out+=$'\n' ;;
      *) out+=$c ;;
    esac
  done
  printf '%s' "$out"
}

# CRLF を先に LF へ畳むのは、次の行継続 join が '\' + LF にしか一致しないため。
CMD=${CMD//$'\r'$'\n'/$'\n'}
CMD=${CMD//$'\r'/$'\n'}

CMD=$(strip_heredocs <<<"$CMD")
[ -z "$CMD" ] && exit 0

[[ $CMD =~ $CANDIDATE_RE ]] || exit 0

# 改行直前のバックスラッシュは行継続でコマンド境界ではない。先に join しないと
# 継続行が自分の 'find' トークンを持たず、フラグが一切検査されない。
SEGMENTS=$(split_segments "${CMD//\\$'\n'/ }")

while IFS= read -r SEG; do
  read -ra TOKS <<<"$SEG"
  [ "${#TOKS[@]}" -eq 0 ] && continue

  # ツールの特定。前置 env 代入とラッパを読み飛ばしてから最初の候補を採る。
  TOOL=""
  TOOL_AT=-1
  BYPASS=0
  for ((i = 0; i < ${#TOKS[@]}; i++)); do
    case "${TOKS[$i]}" in
      sudo | time | nohup | setsid | command | env | xargs | nice | ionice) continue ;;
      CLAUDE_ALLOW_FULL_TREE_SCAN=*)
        strip_token "${TOKS[$i]#*=}"
        [ "$STRIPPED" = 1 ] && BYPASS=1
        continue
        ;;
      *=*) continue ;;
      find | */find | bfs | */bfs) TOOL="find"; TOOL_AT=$i; break ;;
      grep | */grep | egrep | */egrep) TOOL="grep"; TOOL_AT=$i; break ;;
      rg | */rg) TOOL="rg"; TOOL_AT=$i; break ;;
      fd | */fd | fdfind | */fdfind) TOOL="fd"; TOOL_AT=$i; break ;;
      ls | */ls) TOOL="ls"; TOOL_AT=$i; break ;;
      tree | */tree) TOOL="tree"; TOOL_AT=$i; break ;;
      *) break ;;
    esac
  done
  [ "$BYPASS" = 1 ] && continue
  [ "$TOOL_AT" -lt 0 ] && continue

  # ツールごとに「そもそも全走査になり得るか」を判定する。ここで落ちた segment は
  # path 解析まで進まない。
  case "$TOOL" in
    find | tree) ;;
    grep)
      [[ $SEG =~ $GREP_RECURSIVE_RE ]] || continue
      # --exclude-dir は降下を止める（--include / --exclude は出力を絞るだけ）。
      case "$SEG" in *--exclude-dir*) continue ;; esac
      ;;
    rg)
      [[ $SEG =~ $RG_UNRESTRICTED_RE ]] || continue
      ;;
    fd)
      [[ $SEG =~ $FD_UNRESTRICTED_RE ]] || continue
      # fd の -E / --exclude は glob 単位で降下を止める。
      case "$SEG" in *--exclude* | *" -E "*) continue ;; esac
      ;;
    ls)
      [[ $SEG =~ $LS_RECURSIVE_RE ]] || continue
      ;;
  esac

  # 降下を実際に止めているかの判定。`-not -path` / `-path` は出力を絞るだけで
  # descent を止めないため限定に数えない — 今回の事故はまさにこれで、
  # `-not -path '*/node_modules/*'` を付けたまま 136 万エントリを stat していた。
  case "$TOOL" in
    find)
      [[ $SEG =~ $PRUNE_RE ]] && continue
      depth_limited "$SEG" '-maxdepth' && continue
      ;;
    fd)
      depth_limited "$SEG" '--max-depth|--maxdepth|-d' && continue
      ;;
    tree)
      depth_limited "$SEG" '-L' && continue
      ;;
  esac

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
    grep | rg | fd | ls | tree)
      # 非フラグ operand のうち実在するものだけを探索先の手がかりにする。
      #   実在ディレクトリがある -> それが探索先
      #   実在ファイルだけがある -> 明示ファイルを読むだけで tree walk しない
      #   実在するものが無い     -> operand はパターンやオプション値なので cwd 起点
      #
      # 「先頭の非フラグ = 検索パターン、残り = path」という位置決めはできない。
      # -g GLOB / -t TYPE / -A N / -e PAT の値が非フラグとして混じって位置がずれ、
      # 探索先が cwd（= ワイドルート）の走査を見落とす。判定は 1 階層の stat のみで、
      # パス解決は行わない。
      SAW_FILE=0
      for ((i = TOOL_AT + 1; i < ${#TOKS[@]}; i++)); do
        case "${TOKS[$i]}" in
          -*) continue ;;
        esac
        strip_token "${TOKS[$i]}"
        if [ -d "$STRIPPED" ]; then
          PATHS+=("$STRIPPED")
        elif [ -e "$STRIPPED" ]; then
          SAW_FILE=1
        fi
      done
      if [ "${#PATHS[@]}" -eq 0 ]; then
        [ "$SAW_FILE" = 1 ] && continue
        PATHS=("$PWD")
      fi
      ;;
  esac
  [ "${#PATHS[@]}" -eq 0 ] && PATHS=("$PWD")

  for p in "${PATHS[@]}"; do
    is_wide_root "$p" || continue

    emit_deny "$(
      printf '%s\n' \
        "全走査を止めました: ${TOOL} が ${p} を起点にしていて、降下を止める指定がありません（${HEAVY_HIT} を含むルートです）。" \
        "" \
        "-not -path / -path / --include は出力を絞るだけで descent を止めないので、除外にはなりません。実際に降下を止めるのは -prune と -maxdepth（grep なら --exclude-dir、fd なら --exclude）だけです。" \
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
