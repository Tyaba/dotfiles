#!/bin/bash
# SessionStart hook: warn when the local yui MCP proxy is unreachable.
#
# Claude Code does not retry an MCP server that failed to connect at session
# start. If the proxy is down (typically because gcloud credentials expired),
# yui stays disconnected for the whole session even after the proxy recovers,
# so surface the fix before any work starts.
#
# Always exits 0: a down proxy must not block the session.

if [ -f /.dockerenv ] || [ -n "${REMOTE_CONTAINERS:-}" ]; then
  host=host.docker.internal
  login_hint='ホストで yui-login を実行'
else
  host=localhost
  login_hint='! yui-login を実行'
fi
url=${YUI_PROXY_STATUS_URL:-http://${host}:${YUI_PROXY_PORT:-52981}/status}

if curl -fsS -m 2 -o /dev/null "$url" 2>/dev/null; then
  exit 0
fi

message="yui プロキシ (${url}) に接続できません。gcloud の認証切れの可能性があります。${login_hint}し、その後 /mcp で yui を Reconnect してください。"

# systemMessage is shown to the user; additionalContext is given to Claude so
# it does not silently skip the required yui calls.
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
