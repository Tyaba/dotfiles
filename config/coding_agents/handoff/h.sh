#!/usr/bin/env bash
# Run the command an agent staged for this repository or directory.
# Claude Code's `! h` captures output without a TTY, so show the command and
# run it without prompting. Separate worktrees must keep separate handoffs.
set -euo pipefail

usage() {
  printf '%s\n' 'Usage: h [--path|--show|--help]' \
    '  h         Print and consume the staged command, then run it with bash.' \
    '  --path    Print the staging path for the current repository or directory.' \
    '  --show    Print the staged command without consuming it.' \
    '  --help    Show this help.'
}

if [ "$#" -gt 1 ]; then
  usage >&2
  exit 2
fi

case "${1:-}" in
  --help)
    usage
    exit 0
    ;;
  ''|--path|--show) ;;
  *)
    usage >&2
    exit 2
    ;;
esac

key=$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD")
if command -v sha256sum >/dev/null 2>&1; then
  hash=$(printf '%s' "$key" | sha256sum)
else
  hash=$(printf '%s' "$key" | shasum -a 256)
fi
hash=${hash:0:16}
staging_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-handoff"
staged="$staging_dir/$hash.sh"
mkdir -p "$staging_dir"

if [ "${1:-}" = --path ]; then
  printf '%s\n' "$staged"
  exit 0
fi

if [ ! -f "$staged" ]; then
  printf 'h: nothing staged for %s\n' "$key" >&2
  exit 1
fi

if [ "${1:-}" = --show ]; then
  cat "$staged"
  exit 0
fi

printf 'h: running staged command for %s:\n' "$key"
cat "$staged"
printf '\n%s\n' '---'

# Consume before execution so a failed command cannot be repeated by accident.
last="$staging_dir/$hash.last.sh"
mv -f "$staged" "$last"
exec bash "$last"
