#!/bin/bash
# PostToolUse hook: render .mmd/.mermaid files to PNG and display inline.
# Supports Kitty Graphics Protocol (Ghostty, Kitty) and iTerm2 inline images.
#
# Dependencies: @mermaid-js/mermaid-cli (mmdc)
# Install: npm install -g @mermaid-js/mermaid-cli

set -euo pipefail

input=$(cat)

TOOL=$(echo "$input" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# Only act on Write/Edit to .mmd or .mermaid files
case "$FILE_PATH" in
    *.mmd|*.mermaid) ;;
    *) exit 0 ;;
esac

case "$TOOL" in
    Write|Edit) ;;
    *) exit 0 ;;
esac

[ -f "$FILE_PATH" ] || exit 0

OUT_DIR=$(dirname "$FILE_PATH")
BASE=$(basename "$FILE_PATH" | sed 's/\.\(mmd\|mermaid\)$//')
OUT_PNG="${OUT_DIR}/${BASE}.png"

if ! command -v mmdc &>/dev/null; then
    echo "⚠ mmdc not found. Install: npm install -g @mermaid-js/mermaid-cli" >&2
    exit 0
fi

mmdc -i "$FILE_PATH" -o "$OUT_PNG" -t dark -b transparent --scale 2 2>/dev/null || {
    echo "⚠ Failed to render ${FILE_PATH}" >&2
    exit 0
}

display_kitty() {
    local file="$1"
    local data
    data=$(base64 < "$file")
    local chunk_size=4096
    local len=${#data}
    local offset=0

    while [ "$offset" -lt "$len" ]; do
        local remaining=$((len - offset))
        local size=$chunk_size
        [ "$remaining" -lt "$size" ] && size=$remaining
        local chunk="${data:$offset:$size}"
        offset=$((offset + size))

        if [ "$offset" -ge "$len" ]; then
            printf '\033_Ga=T,f=100,m=0;%s\033\\' "$chunk"
        else
            printf '\033_Ga=T,f=100,m=1;%s\033\\' "$chunk"
        fi
    done
    echo ""
}

display_iterm2() {
    local file="$1"
    local data
    data=$(base64 < "$file")
    local size
    size=$(wc -c < "$file" | tr -d ' ')
    printf '\033]1337;File=inline=1;size=%s;preserveAspectRatio=1:%s\a' "$size" "$data"
    echo ""
}

echo "📊 Rendered: ${OUT_PNG}"

if [ "${TERM_PROGRAM:-}" = "ghostty" ] || [ "${TERM:-}" = "xterm-ghostty" ]; then
    display_kitty "$OUT_PNG"
elif [ "${TERM_PROGRAM:-}" = "iTerm.app" ]; then
    display_iterm2 "$OUT_PNG"
elif [ -n "${KITTY_PID:-}" ]; then
    display_kitty "$OUT_PNG"
else
    echo "(View: open ${OUT_PNG})"
fi
