#!/bin/bash
# Make sure the shared Playwright MCP daemon is listening, starting it only
# when none is running.
#
# In devcontainers every Claude Code session talks to one
# `@playwright/mcp --port 8931` daemon over HTTP (see
# config/coding_agents/mcp.json.erb) instead of spawning its own stdio server.
# This script is the single place that brings the daemon up:
#
#   - the `claude` wrapper (config/coding_agents/playwright-mcp/claude-wrapper.sh)
#     runs it before exec'ing the real CLI, so the daemon is listening before
#     Claude Code connects its MCP servers
#   - the SessionStart hook (config/coding_agents/hooks/playwright-mcp-ensure.sh)
#     runs it as a fallback for sessions started without the wrapper; it cannot
#     win the race against the MCP connection, so it only enables `/mcp`
#     reconnect
#
# Behaviour:
#   - a daemon is already listening -> do nothing (exit 0)
#   - none is listening             -> start one, wait for it, then install the
#                                      matching Chromium in the background
#                                      (exit 3)
#   - it did not come up in time    -> exit 1 (see the log)
#
# Parallel sessions may call this at the same moment; flock serialises them so
# only the first one starts a daemon and the rest find it listening.

set -u

port="${PLAYWRIGHT_MCP_PORT:-8931}"
log="${PLAYWRIGHT_MCP_LOG:-/tmp/playwright-mcp.log}"
lock="${XDG_RUNTIME_DIR:-/tmp}/playwright-mcp-${port}.lock"

listening() {
  (exec 3<>"/dev/tcp/localhost/${port}") 2>/dev/null
}

listening && exit 0

export PATH="$HOME/.local/share/mise/shims:$PATH"
if ! command -v npx >/dev/null 2>&1; then
  echo "playwright-mcp: npx not found; cannot start the shared daemon" >&2
  exit 1
fi

if command -v flock >/dev/null 2>&1; then
  exec 9>"$lock"
  flock -w 60 9 || true
  # Another session may have started it while this one waited for the lock.
  listening && exit 0
fi

# Chromium is missing on a freshly created container (~/.cache is not a
# volume); that is also when the system libraries it needs are missing.
browser_cache="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
fresh_browser=0
compgen -G "${browser_cache}/chromium_headless_shell-*" >/dev/null || fresh_browser=1

# --headless --browser chromium: the container has no display and no Chrome
#   channel, only Playwright's own Chromium.
# --isolated: keep each client's profile in memory so concurrent sessions do
#   not fight over one profile directory.
# The server checks the Host header against what it bound to, so bind to
#   localhost (the MCP URL must say localhost too, not 127.0.0.1).
# setsid detaches the daemon from this process group so it outlives the caller.
setsid nohup npx -y @playwright/mcp@latest --port "$port" --host localhost \
  --headless --browser chromium --isolated >"$log" 2>&1 </dev/null &

for _ in $(seq 1 80); do
  if listening; then
    # Install the Chromium build that matches the daemon's Playwright. This is
    # a no-op when it is already there, and it runs in the background because
    # the browser is only needed at the first browser_* tool call.
    deps=()
    if [ "$fresh_browser" = 1 ] && sudo -n true 2>/dev/null; then
      deps=(--with-deps)
    fi
    setsid nohup npx -y -p @playwright/mcp@latest playwright install "${deps[@]}" \
      chromium chromium-headless-shell >>"$log" 2>&1 </dev/null &
    exit 3
  fi
  sleep 0.25
done

echo "playwright-mcp: the shared daemon did not start listening on localhost:${port}; see ${log}" >&2
exit 1
