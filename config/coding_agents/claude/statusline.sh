#!/bin/bash
input=$(cat)

# Extract every field in a single jq pass. One process per render instead of
# one per field: the status line is re-rendered constantly, and with several
# parallel sessions sharing one dev container the subprocess count dominates.
FIELDS=$(jq -r '
  [ (.model.display_name // "?")
  , (.context_window.used_percentage // 0 | floor)
  , (.cost.total_cost_usd // 0)
  , (.cost.total_lines_added // 0)
  , (.cost.total_lines_removed // 0)
  , (if .rate_limits.five_hour.used_percentage == null then ""
     else (.rate_limits.five_hour.used_percentage | round | tostring) end)
  , (if .rate_limits.seven_day.used_percentage == null then ""
     else (.rate_limits.seven_day.used_percentage | round | tostring) end)
  ] | @tsv' <<< "$input")
IFS=$'\t' read -r MODEL PCT COST LINES_ADD LINES_DEL FIVE_H WEEK <<< "$FIELDS"
MODEL=${MODEL:-?}
PCT=${PCT:-0}
COST=${COST:-0}
LINES_ADD=${LINES_ADD:-0}
LINES_DEL=${LINES_DEL:-0}

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
DIM='\033[2m'
RESET='\033[0m'

# Context bar with color thresholds
BAR_WIDTH=15
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
if [ "$PCT" -ge 80 ]; then
    BAR_COLOR="$RED"
elif [ "$PCT" -ge 50 ]; then
    BAR_COLOR="$YELLOW"
else
    BAR_COLOR="$GREEN"
fi
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /▓}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

RATE=""
if [ -n "$FIVE_H" ]; then
    if [ "$FIVE_H" -ge 80 ]; then RATE_5_COLOR="$RED"
    elif [ "$FIVE_H" -ge 50 ]; then RATE_5_COLOR="$YELLOW"
    else RATE_5_COLOR="$GREEN"; fi
    RATE="${RATE_5_COLOR}5h:${FIVE_H}%${RESET}"
fi
if [ -n "$WEEK" ]; then
    if [ "$WEEK" -ge 80 ]; then RATE_7_COLOR="$RED"
    elif [ "$WEEK" -ge 50 ]; then RATE_7_COLOR="$YELLOW"
    else RATE_7_COLOR="$GREEN"; fi
    RATE="${RATE:+$RATE }${RATE_7_COLOR}7d:${WEEK}%${RESET}"
fi

printf -v COST_FMT '$%.2f' "$COST"
RATE_SECTION=""
[ -n "$RATE" ] && RATE_SECTION=" │ ${RATE}"
echo -e "${DIM}[${MODEL}]${RESET} ${BAR_COLOR}${BAR} ${PCT}%${RESET} │ ${CYAN}${COST_FMT}${RESET} │ ${GREEN}+${LINES_ADD}${RESET}/${RED}-${LINES_DEL}${RESET}${RATE_SECTION}"

# ---------------------------------------------------------------------------
# Line 2: git status + changed files.
#
# A single porcelain call replaces `rev-parse` + `branch --show-current` +
# three `diff` variants + `ls-files --others`, and --no-optional-locks keeps
# the render from taking index.lock while the user runs git in the same tree.
#
# Even reduced to one call it is not cheap: on a bind-mounted worktree the
# "refresh index" stat pass over every tracked file costs 150ms+, and the line
# is re-rendered far more often than the working tree actually changes. So the
# rendered line is cached per worktree and served immediately; when it goes
# stale the refresh runs detached, so no render ever blocks on git.
# ---------------------------------------------------------------------------
CACHE_TTL=3
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
CACHE_FILE="$CACHE_DIR/${PWD//\//%}"

now() {
    # bash 4.2+ formats time without forking; macOS ships bash 3.2, which cannot.
    printf -v NOW '%(%s)T' -1 2>/dev/null || NOW=$(date +%s)
}

git_line() {
    local status branch xy path counts files shown staged unstaged untracked
    status=$(git --no-optional-locks status --porcelain=v1 --branch 2>/dev/null)
    [ -n "$status" ] || return 0

    branch=""; staged=0; unstaged=0; untracked=0; files=""; shown=0
    while IFS= read -r line; do
        if [ "${line:0:3}" = "## " ]; then
            branch=${line:3}
            branch=${branch%%...*}
            [ "$branch" = "HEAD (no branch)" ] && branch="HEAD"
            continue
        fi
        xy=${line:0:2}
        if [ "$xy" = "??" ]; then
            untracked=$((untracked + 1))
            continue
        fi
        [ "${xy:0:1}" != " " ] && staged=$((staged + 1))
        [ "${xy:1:1}" != " " ] && unstaged=$((unstaged + 1))
        if [ "$shown" -lt 8 ]; then
            path=${line:3}
            path=${path##* -> }   # renames are reported as "old -> new"
            path=${path%\"}
            files="${files}${path##*/} "
            shown=$((shown + 1))
        fi
    done <<< "$status"

    counts=""
    [ "$staged" -gt 0 ] && counts="${GREEN}●${staged}${RESET}"
    [ "$unstaged" -gt 0 ] && counts="${counts} ${YELLOW}●${unstaged}${RESET}"
    [ "$untracked" -gt 0 ] && counts="${counts} ${RED}●${untracked}${RESET}"

    printf '%b' "${DIM}🌿 ${branch}${RESET} ${counts} ${DIM}${files}${RESET}"
}

write_cache() {
    # $1 = timestamp, $2 = rendered line. Written via rename so a concurrent
    # reader never sees a half-written file.
    mkdir -p "$CACHE_DIR" 2>/dev/null || return 0
    local tmp="$CACHE_FILE.$$"
    { printf '%s\n' "$1"; printf '%s\n' "$2"; } > "$tmp" 2>/dev/null &&
        mv -f "$tmp" "$CACHE_FILE" 2>/dev/null
}

CACHED_AT=0
CACHED_LINE=""
if [ -r "$CACHE_FILE" ]; then
    { IFS= read -r CACHED_AT; IFS= read -r CACHED_LINE; } < "$CACHE_FILE" 2>/dev/null
    case $CACHED_AT in ''|*[!0-9]*) CACHED_AT=0 ;; esac
fi

now
if [ "$CACHED_AT" -eq 0 ]; then
    # No cache for this worktree yet: pay for one synchronous render.
    CACHED_LINE=$(git_line)
    write_cache "$NOW" "$CACHED_LINE"
elif [ $((NOW - CACHED_AT)) -ge "$CACHE_TTL" ]; then
    # Claim the slot first so sibling renders in the same worktree see a fresh
    # timestamp and do not each spawn their own refresh.
    write_cache "$NOW" "$CACHED_LINE"
    (
        line=$(git_line)
        now
        write_cache "$NOW" "$line"
    ) > /dev/null 2>&1 &
fi

[ -n "$CACHED_LINE" ] && printf '%s\n' "$CACHED_LINE"
exit 0
