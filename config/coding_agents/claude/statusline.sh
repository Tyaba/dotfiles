#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

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

# Line 1: model + context + cost + lines changed
COST_FMT=$(printf '$%.2f' "$COST")
echo -e "${DIM}[${MODEL}]${RESET} ${BAR_COLOR}${BAR} ${PCT}%${RESET} │ ${CYAN}${COST_FMT}${RESET} │ ${GREEN}+${LINES_ADD}${RESET}/${RED}-${LINES_DEL}${RESET}"

# Line 2: git status + changed files
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null | head -8)
    STAGED_COUNT=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNSTAGED_COUNT=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED_COUNT=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    GIT_COUNTS=""
    [ "$STAGED_COUNT" -gt 0 ] && GIT_COUNTS="${GREEN}●${STAGED_COUNT}${RESET}"
    [ "$UNSTAGED_COUNT" -gt 0 ] && GIT_COUNTS="${GIT_COUNTS} ${YELLOW}●${UNSTAGED_COUNT}${RESET}"
    [ "$UNTRACKED_COUNT" -gt 0 ] && GIT_COUNTS="${GIT_COUNTS} ${RED}●${UNTRACKED_COUNT}${RESET}"

    FILE_LIST=""
    if [ -n "$CHANGED_FILES" ]; then
        FILE_LIST=$(echo "$CHANGED_FILES" | while read -r f; do
            basename "$f"
        done | tr '\n' ' ')
    fi

    echo -e "${DIM}🌿 ${BRANCH}${RESET} ${GIT_COUNTS} ${DIM}${FILE_LIST}${RESET}"
fi
