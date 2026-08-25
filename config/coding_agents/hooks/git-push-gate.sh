#!/bin/bash
# git-push-gate.sh — Bash ツール用の PreToolUse hook。
# 保護対象ブランチへの `git push` と force-push 系を gate する。
#
# 決定ポリシー:
#   - 保護対象外への通常 push           -> 自動 allow
#   - 保護対象ブランチへの push        -> ask（承認プロンプト）
#   - force-push（--force, --force-with-lease, -f, refspec 先頭の '+',
#     --mirror, --all）                 -> ask
#   - それ以外                          -> fall through（無判定）
#
# 保護対象の集合は '|'、','、空白で区切った bash `case` パターンのリスト
# （例: "main|master", "main, release-*"）。CLAUDE_PROTECTED_BRANCHES 環境変数で
# リポジトリごとに上書きできる（settings.local.json の `env` ブロックは
# gitignore 対象なので、上書きは `copier update` を跨いで残る）。空文字を
# 設定すると通常 push の gate が丸ごと無効になる — 既定ブランチへの直 push が
# 通常ワークフローである実験用リポジトリ向け。
#
# この上書きが緩めるのは「通常 push」の gate だけ。force-push はここで無条件に
# gate され続け、pre-tool-block-destructive.py も保護対象ブランチへの force-push
# に独自の hard deny を保持する。
#
# 既知の誤検知（fail-closed 方向）: クォート文字列をシェルとして解釈しないため、
# 同一 segment 内のクォート文字列に保護ブランチ名の後続語があると refspec 候補に
# なり得る（余分な ask が 1 回出るだけで、見落とし側には倒れない）。

set -uo pipefail

# tyaba-env 生成プロジェクトは同じ hook を `.claude/hooks/` に git 管理で持つ。
# dotfiles 版と両方が発火すると、保護ブランチへの push 1 回につき ask
# プロンプトが 2 回出る。プロジェクト側に実体があればそちらへ委ねる。
# `.devcontainer/**/claude-hooks/` のような gitignore 配下の複製は worktree に
# 存在しないため、ここでは判定に使わない。
if [ -n "${CLAUDE_PROJECT_DIR-}" ] &&
   [ -x "$CLAUDE_PROJECT_DIR/.claude/hooks/git-push-gate.sh" ]; then
  exit 0
fi

PROTECTED_BRANCHES="${CLAUDE_PROTECTED_BRANCHES-main|master}"

# 分割はループ外で 1 回だけ行う: 値はループ不変。パターンを 1 つずつ照合するのは、
# パラメータ展開で生じた '|' が `case` にとって選択（alternation）ではなくリテラル
# 文字になるため。`-d ''` は改行を越えて読むので、複数行の値もタブ・空白・カンマ
# 区切りと同様に分割される。'\r' を区切り集合に含めるのは、CRLF 終端の値が
# 'master\r' を最後のパターンとして残し、何にも一致しなくなるのを防ぐため。
# `read -d ''` は区切りの NUL に出会わず常に 1 で終了するので、`|| true` を付けて
# 将来このファイルに `set -e` が入っても無害にしておく。
IFS=$'|, \t\r\n' read -r -d '' -a PROTECTED_PATTERNS <<<"$PROTECTED_BRANCHES" || true

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$CMD" ] && exit 0

case "$CMD" in
  *push*) ;;
  *) exit 0 ;;
esac

emit() {
  jq -nc --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

# 遅延キャッシュ: refspec を持たない push が無い限り現在ブランチは不要。
CUR=""

# segment が push だと判明した時点で立てるフラグ。'push' に言及するだけの
# コマンドに `allow` を与えず、無判定で fall through させるため
# （ヘッダの決定ポリシーは push 以外に判定を出さないと約束している）。
SAW_PUSH=0

# 改行直前のバックスラッシュは行継続でありコマンド境界ではないので、分割の前に
# この組を join する。そこで分割してしまうと継続行は自分の 'git' トークンを
# 持たず、そのフラグが一切検査されない: 'git push \' + 改行 + '  --force origin
# feat/x' が force 判定を丸ごとすり抜ける。
#
# CRLF を先に LF へ畳むのは、下の join が '\' + LF にしか一致しないため。
# '\' + CRLF の継続は join を生き延び、`tr` セットの '\r' がそれを独立した
# segment へ切り離してしまう — join が塞ぐはずの fail-open そのもの。'\r' は
# 区切りとして残す: 単独の CR にも segment を終端させ、CRLF のコマンドが
# 'main\r' を refspec として残して何にも一致しなくなるのを防ぐため。
CMD=${CMD//$'\r'$'\n'/$'\n'}
SEGMENTS=$(printf '%s' "${CMD//\\$'\n'/ }" | tr ';&|<>()\r' '\n\n\n\n\n\n\n\n')

# コマンドは 1 本の文字列として走査せず、シェル演算子で segment へ分割する。
# 一括走査は最初の演算子で止まり、後続の `git push` をすべて見落とす
# ('git push origin feat/x && git push origin main')。かといって演算子を空白へ
# 畳むとコマンド境界が消え、次のコマンドの語が refspec として読まれてしまう
# ('git push && gh pr create' -> 'pr create')。分割なら両方が成り立つ: 全 segment
# が検査され、かつ各 segment は自分自身が refspec を持つかどうかを知っている。
# 既存の改行はそのまま segment の区切りになる。
while IFS= read -r SEG; do
  read -ra SEGTOKS <<<"$SEG"

  # segment を push と見なすのは、'git' トークンの後に単独の 'push' トークンが
  # 続くときだけ。部分文字列で照合すると `git commit -m "push it"` を push と
  # 誤認し、現在ブランチに対して判定してしまう。
  PUSH_AT=-1
  GIT_AT=-1
  for ((i=0; i<${#SEGTOKS[@]}; i++)); do
    case "${SEGTOKS[$i]}" in
      git|*/git) [ "$GIT_AT" -lt 0 ] && GIT_AT=$i ;;
      push) [ "$GIT_AT" -ge 0 ] && { PUSH_AT=$i; break; } ;;
    esac
  done
  [ "$PUSH_AT" -lt 0 ] && continue
  SAW_PUSH=1

  # force / wide push の検出（フラグ形式）。この segment にスコープを絞り、
  # コマンドライン中の別の場所にある無関係な `--force` で発火しないようにする。
  if printf '%s' "$SEG" | grep -qE '(^|[[:space:]])(--force(-with-lease)?|--mirror|--all)([[:space:]=]|$)'; then
    emit ask "Force or wide git push detected; explicit approval required"
  fi
  # `-f` は他の短オプションと束ねられ得る（`git push -fu origin feat/x`）。
  # `git push` の短オプションで 'f' を使うものは他に無いので、単一ダッシュの
  # 束の中の 'f' は force を意味する。
  if printf '%s' "$SEG" | grep -qE '(^|[[:space:]])-[[:alnum:]]*f[[:alnum:]]*([[:space:]]|$)'; then
    emit ask "git push with -f (force) detected"
  fi

  # 'push' 以降のトークンからフラグを除き、positional 引数
  # （remote + refspec）を集める。
  POSITIONALS=()
  SKIP=0
  for ((i=PUSH_AT+1; i<${#SEGTOKS[@]}; i++)); do
    tok=${SEGTOKS[$i]}
    if [ "$SKIP" = 1 ]; then SKIP=0; continue; fi
    case "$tok" in
      -o|--push-option) SKIP=1; continue ;;
      --*=*|--*|-*) continue ;;
    esac
    POSITIONALS+=("$tok")
  done

  # 対象 refspec を決める。positional が 1 つ以下なら refspec は与えられていない
  # （remote のみ、または何も無し）ので、push は現在ブランチへ向かう。
  REFSPECS=()
  if [ "${#POSITIONALS[@]}" -le 1 ]; then
    [ -z "$CUR" ] && CUR=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    REFSPECS+=("$CUR")
  else
    for ((i=1; i<${#POSITIONALS[@]}; i++)); do
      REFSPECS+=("${POSITIONALS[$i]}")
    done
  fi

  for rs in ${REFSPECS[@]+"${REFSPECS[@]}"}; do
    # `read -ra` はクォート除去をしないため、`git push origin "main"` は
    # '"main"' のまま届き、何にも一致しない。ブランチ名にクォートは使えない
    # ので、除去しても意味が変わる入力は存在しない。
    rs=${rs//\"/}
    rs=${rs//\'/}
    [ -z "$rs" ] && continue
    if [[ "$rs" == +* ]]; then
      emit ask "Refspec '$rs' has force prefix '+'"
    fi
    if [[ "$rs" == *:* ]]; then
      DST=${rs#*:}
    else
      DST=$rs
    fi
    DST=${DST#refs/heads/}
    for pat in ${PROTECTED_PATTERNS[@]+"${PROTECTED_PATTERNS[@]}"}; do
      [ -z "$pat" ] && continue
      case "$DST" in
        $pat) emit ask "Push targets protected branch '$DST'" ;;
      esac
    done
  done
done <<<"$SEGMENTS"

[ "$SAW_PUSH" = 0 ] && exit 0

emit allow "Push to non-protected branch"
