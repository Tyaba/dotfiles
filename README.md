# dotfiles
> Accio, My Utensils!

## Usage
### Clone this repository
```shell
git clone --recursive https://github.com/Tyaba/dotfiles.git
```

## Prerequisites
```shell
sudo apt update
sudo apt install -y curl lsb-release
```
### wslの場合
windowsのPATHが入っているとinstall済と誤判定するので直す
sudo emacs /etc/wsl.conf
```
# WindowsのPATHを引き継がない設定を追記する
[interop]
appendWindowsPath = false
```

### Dry-run
```shell
./install.sh -n
```

### Apply
```shell
./install.sh
```

### Add new cookbook
```shell
mkdir cookbooks/:app_name
$EDITOR cookbooks/:app_name/default.rb
$EDITOR roles/$(uname)/default.rb
```

## Coding Agents

### Configuration Structure

```
config/
└── coding_agents/
    ├── claude/             # Claude Code-specific (settings.json, CLAUDE.md, etc.)
    ├── codex/              # Codex CLI-specific (AGENTS.md)
    ├── cursor/             # Cursor-specific (rules/, hooks.json)
    ├── hooks/              # Shared hooks
    ├── skills/             # Shared skills
    ├── mcp.json.erb        # MCP server definitions (ERB template)
    └── user-rules.md       # Shared user rules (Claude Code / Cursor)
```

### Deployment

`roles/base/default.rb` deploys configurations via symlinks:

| Source | Target |
|---|---|
| `config/coding_agents/claude/settings.json` | `~/.claude/settings.json` |
| `config/coding_agents/skills/` | `~/.claude/skills/`, `~/.cursor/skills/` |
| `config/coding_agents/mcp.json.erb` | `~/.mcp.json`, `~/.cursor/mcp.json` |
| `config/coding_agents/codex/AGENTS.md` | `~/.codex/AGENTS.md` |

### Codex Offload (via MCP server)

Claude Code tasks are automatically offloaded to Codex via the `codex mcp-server` MCP integration. Claude calls `mcp__codex__codex` as a regular tool, enabling natural auto-delegation. See `config/coding_agents/skills/codex-offload/SKILL.md` for prompt composition guidelines.

**Setup (after `./install.sh`):**
```shell
codex login          # Authenticate with ChatGPT Enterprise (one-time)
```

**Key features:**
- `base-instructions` parameter allows dynamic injection of project-specific rules into Codex
- `codex-reply` enables multi-turn Codex sessions via `threadId`
- `~/.codex/AGENTS.md` provides static global rules for direct Codex CLI usage

**Constraints:**
- Requires local OAuth authentication (browser flow) -- not available in CI/headless environments
