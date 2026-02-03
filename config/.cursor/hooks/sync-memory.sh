#!/bin/bash
# Sync memory.jsonl after memory MCP execution

# Read JSON input from stdin
input=$(cat)

# Extract tool_name from JSON input
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

# Check if this is a memory MCP tool
# Memory MCP tools: search_nodes, create_entities, add_observations, etc.
if [[ "$tool_name" =~ ^(search_nodes|create_entities|add_observations|delete_entities|create_relations|delete_relations|open_nodes|read_graph)$ ]]; then
    cd ~/ghq/github.com/Tyaba/vault || exit 1
    git add mcp_server_memory/memory.jsonl

    if ! git diff --cached --quiet; then
        git commit -m 'Auto-sync: memory update via MCP'
        git push origin main
    fi
fi
