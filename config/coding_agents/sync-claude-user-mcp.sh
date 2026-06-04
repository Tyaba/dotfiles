#!/usr/bin/env bash
set -euo pipefail

# Claude Code discovers project-scoped .mcp.json files by walking cwd ancestors.
# On host machines, projects usually live under $HOME, so ~/.mcp.json is found.
# In devcontainers, projects live under /workspaces/<name>, outside $HOME.
# That ancestor walk stops before /home/vscode, so ~/.mcp.json is ignored there.
# User-scoped MCP entries are stored in ~/.claude.json instead.
# Claude Code reads that user scope independently from cwd.
# This sync keeps config/coding_agents/mcp.json.erb as the single source of truth.

MCP_JSON="${MCP_JSON:-$HOME/.mcp.json}"
USER_CONFIG="${USER_CONFIG:-$HOME/.claude.json}"

log() {
  echo "[sync-claude-user-mcp] $*" >&2
}

if ! command -v claude >/dev/null 2>&1; then
  log "warning: claude command not found; skipping"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  log "warning: jq command not found; skipping"
  exit 0
fi

if [ ! -f "$MCP_JSON" ]; then
  log "warning: $MCP_JSON not found; skipping"
  exit 0
fi

# Remove user-scope entries that no longer exist in $MCP_JSON. Without this,
# servers dropped from mcp.json.erb stay registered in the user scope forever,
# causing duplicates next to claude.ai connectors (e.g. a leftover "notion"
# stdio entry shadowing the official Notion connector).
if [ -f "$USER_CONFIG" ]; then
  expected_names=$(jq -r '.mcpServers // {} | keys[]?' "$MCP_JSON" | sort -u)
  current_names=$(jq -r '.mcpServers // {} | keys[]?' "$USER_CONFIG" | sort -u)
  while IFS= read -r stale; do
    [ -z "$stale" ] && continue
    log "removing stale user-scope $stale"
    claude mcp remove --scope user "$stale" >/dev/null 2>&1 || true
  done < <(comm -23 <(echo "$current_names") <(echo "$expected_names"))
fi

while IFS= read -r row; do
  decode() {
    echo "$row" | base64 --decode | jq -r "$1"
  }

  name=$(decode '.key')
  type=$(decode '.value.type // "stdio"')

  claude mcp remove --scope user "$name" >/dev/null 2>&1 || true

  case "$type" in
    http|sse)
      url=$(decode '.value.url')
      claude mcp add --scope user --transport "$type" "$name" "$url" >/dev/null
      ;;
    stdio)
      cmd=$(decode '.value.command')
      args=()
      while IFS= read -r a; do
        args+=("$a")
      done < <(echo "$row" | base64 --decode | jq -r '.value.args[]?')

      if [ ${#args[@]} -gt 0 ]; then
        claude mcp add --scope user "$name" -- "$cmd" "${args[@]}" >/dev/null
      else
        claude mcp add --scope user "$name" -- "$cmd" >/dev/null
      fi
      ;;
    *)
      log "unknown transport for $name: $type"
      continue
      ;;
  esac

  log "synced $name ($type)"
done < <(jq -r '.mcpServers | to_entries[] | @base64' "$MCP_JSON")
