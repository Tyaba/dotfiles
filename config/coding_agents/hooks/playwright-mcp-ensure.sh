#!/bin/bash
# SessionStart hook (devcontainer only): start the shared Playwright MCP daemon
# if no daemon is running.
#
# The `claude` wrapper normally starts it before the CLI launches. This hook
# covers sessions that bypassed the wrapper (the CLI invoked by absolute path,
# an IDE extension). Claude Code connects MCP servers concurrently with this
# hook and does not retry, so when the daemon had to be started here the
# playwright server has already failed for this session; tell the user to
# reconnect it.
#
# Always exits 0: the daemon being down must not block the session.

# ~/.claude/hooks is a symlink to config/coding_agents/hooks; resolve it to
# reach the sibling playwright-mcp/ directory.
hooks_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
bash "$hooks_dir/../playwright-mcp/ensure.sh" >/dev/null 2>&1
status=$?

case "$status" in
  0) exit 0 ;;
  3) message="共有 playwright MCP デーモン (localhost:8931) が停止していたため起動しました。このセッションの playwright は接続に失敗しているので、/mcp で playwright を Reconnect してください。" ;;
  *) message="共有 playwright MCP デーモン (localhost:8931) を起動できませんでした。/tmp/playwright-mcp.log を確認してください。" ;;
esac

python3 - "$message" <<'PY'
import json
import sys

message = sys.argv[1]
print(json.dumps({
    "systemMessage": message,
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": message,
    },
}, ensure_ascii=False))
PY
exit 0
