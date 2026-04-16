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
├── coding_agents/          # Claude Code / Cursor shared config
│   ├── claude/             # Claude Code-specific (settings.json, CLAUDE.md, etc.)
│   ├── cursor/             # Cursor-specific (rules/, hooks.json)
│   ├── hooks/              # Shared hooks
│   ├── skills/             # Shared skills
│   ├── mcp.json.erb        # MCP server definitions (ERB template)
│   └── user-rules.md       # Shared user rules
└── codex/
    └── AGENTS.md           # Codex CLI global instructions
```

### Deployment

`roles/base/default.rb` deploys configurations via symlinks:

| Source | Target |
|---|---|
| `config/coding_agents/claude/settings.json` | `~/.claude/settings.json` |
| `config/coding_agents/skills/` | `~/.claude/skills/`, `~/.cursor/skills/` |
| `config/coding_agents/mcp.json.erb` | `~/.mcp.json`, `~/.cursor/mcp.json` |
| `config/codex/AGENTS.md` | `~/.codex/AGENTS.md` |

### Codex Offload (via codex-plugin-cc)

Claude Code tasks can be offloaded to Codex via the `codex-plugin-cc` plugin. See `config/coding_agents/skills/codex-offload/SKILL.md` for delegation guidelines.

**Setup (after `./install.sh`):**
```shell
codex login          # Authenticate with ChatGPT Enterprise
/codex:setup         # Verify plugin readiness (inside Claude Code)
```

**Constraints:**
- Requires local OAuth authentication (browser flow) -- not available in CI/headless environments
- Codex reads `~/.codex/AGENTS.md` but does NOT read Claude's `CLAUDE.md` or `user-rules.md`
