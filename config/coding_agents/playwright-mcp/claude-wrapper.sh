#!/bin/bash
# `claude` wrapper for devcontainers: bring up the shared Playwright MCP daemon,
# then exec the real Claude Code CLI.
#
# Claude Code connects its MCP servers concurrently with SessionStart hooks and
# never retries a server that failed, so the daemon must already be listening
# when the CLI starts. Sessions are launched in several ways (`bash -lc` from
# the project launcher, interactive zsh, herdr), and a command on PATH is the
# one thing all of them go through. roles/devcontainer links this file as
# ~/.local/bin/claude, which comes before the mise-managed CLI on PATH.
#
# ensure.sh returns immediately when the daemon is up, so the cost per launch
# is one TCP connect. A failure to start it never blocks Claude Code.

self="$(readlink -f "${BASH_SOURCE[0]}")"
here="$(dirname "$self")"

bash "$here/ensure.sh" >/dev/null || true

# Exec the next `claude` on PATH that is not this wrapper.
while IFS= read -r candidate; do
  [ "$(readlink -f "$candidate")" = "$self" ] && continue
  [ -x "$candidate" ] || continue
  # The first runnable candidate replaces this process; the loop never resumes.
  # shellcheck disable=SC2093
  exec "$candidate" "$@"
done < <(type -ap claude)

echo "claude wrapper: the Claude Code CLI was not found on PATH" >&2
exit 127
