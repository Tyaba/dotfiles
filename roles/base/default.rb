if run_command('test -d /etc/systemd', error: false).exit_status == 0
  [
    "#{ENV['HOME']}/.config",
    "#{ENV['HOME']}/.config/systemd",
    "#{ENV['HOME']}/.config/systemd/user",
  ].each do |dir|
    directory dir do
      owner node[:user] if node[:user]
    end
  end
end

root_dir = File.expand_path('../../..', __FILE__)
include_recipe File.join(root_dir, 'lib', 'helper')

# Coding agents (Cursor / Claude Code shared config)
# Skills (shared)
dotfile '.cursor/skills' => 'coding_agents/skills'
dotfile '.claude/skills' => 'coding_agents/skills'

# Hooks (shared)
dotfile '.cursor/hooks' => 'coding_agents/hooks'
dotfile '.claude/hooks' => 'coding_agents/hooks'

# User rules (shared across all workspaces)
dotfile '.claude/user-rules.md' => 'coding_agents/user-rules.md'

user_rules_erb = File.join(root_dir, 'config/coding_agents/cursor/rules/user-rules.mdc.erb')
user_rules_md = File.read(File.join(root_dir, 'config/coding_agents/user-rules.md'))

execute "rm -f #{ENV['HOME']}/.cursor/rules" do
  only_if "test -L #{ENV['HOME']}/.cursor/rules"
end

directory "#{ENV['HOME']}/.cursor/rules" do
  user node[:user] if node[:user]
end

template "#{ENV['HOME']}/.cursor/rules/user-rules.mdc" do
  source user_rules_erb
  variables(user_rules: user_rules_md)
  user node[:user] if node[:user]
  mode '0644'
end

# Cursor-specific
dotfile '.cursor/rules/coding.mdc' => 'coding_agents/cursor/rules/coding.mdc'
dotfile '.cursor/hooks.json' => 'coding_agents/cursor/hooks.json'

# Claude Code-specific
dotfile '.claude/CLAUDE.md' => 'coding_agents/claude/CLAUDE.md'
dotfile '.claude/output-styles' => 'coding_agents/claude/output-styles'
dotfile '.claude/statusline.sh' => 'coding_agents/claude/statusline.sh'
dotfile '.claude/render-diagram.sh' => 'coding_agents/claude/render-diagram.sh'

# Claude Code settings.json (ERB-rendered, branches on DOTFILES_ROLE)
claude_settings_erb = File.join(root_dir, 'config/coding_agents/claude/settings.json.erb')

directory "#{ENV['HOME']}/.claude" do
  user node[:user] if node[:user]
end

execute "rm -f #{ENV['HOME']}/.claude/settings.json" do
  only_if "test -L #{ENV['HOME']}/.claude/settings.json"
end
template "#{ENV['HOME']}/.claude/settings.json" do
  source claude_settings_erb
  user node[:user] if node[:user]
  mode '0644'
end

# Codex-specific
codex_agents_erb = File.join(root_dir, 'config/coding_agents/codex/AGENTS.md.erb')
codex_config_erb = File.join(root_dir, 'config/coding_agents/codex/config.toml.erb')

directory "#{ENV['HOME']}/.codex" do
  user node[:user] if node[:user]
end

execute "rm -f #{ENV['HOME']}/.codex/AGENTS.md" do
  only_if "test -L #{ENV['HOME']}/.codex/AGENTS.md"
end
template "#{ENV['HOME']}/.codex/AGENTS.md" do
  source codex_agents_erb
  user node[:user] if node[:user]
  mode '0644'
end

execute "rm -f #{ENV['HOME']}/.codex/config.toml" do
  only_if "test -L #{ENV['HOME']}/.codex/config.toml"
end
template "#{ENV['HOME']}/.codex/config.toml" do
  source codex_config_erb
  user node[:user] if node[:user]
  mode '0644'
end

# MCP settings (template generates both Cursor and Claude Code configs)
mcp_erb = File.join(root_dir, 'config/coding_agents/mcp.json.erb')

directory "#{ENV['HOME']}/.cursor" do
  user node[:user] if node[:user]
end

execute "rm -f #{ENV['HOME']}/.mcp.json" do
  only_if "test -L #{ENV['HOME']}/.mcp.json"
end
template "#{ENV['HOME']}/.mcp.json" do
  source mcp_erb
  user node[:user] if node[:user]
  mode '0644'
end

sync_user_mcp = File.join(root_dir, 'config/coding_agents/sync-claude-user-mcp.sh')

# Expose the sync script as a re-runnable command. Claude Code's first OAuth
# login can rewrite ~/.claude.json and drop the mcpServers populated here, so
# users need a low-friction way to re-sync after login completes.
directory "#{ENV['HOME']}/.local/bin" do
  user node[:user] if node[:user]
end

link "#{ENV['HOME']}/.local/bin/claude-sync-mcp" do
  to sync_user_mcp
end

execute 'sync ~/.mcp.json into claude user scope' do
  command "bash #{sync_user_mcp}"
  user node[:user] if node[:user]
end

execute "rm -f #{ENV['HOME']}/.cursor/mcp.json" do
  only_if "test -L #{ENV['HOME']}/.cursor/mcp.json"
end
template "#{ENV['HOME']}/.cursor/mcp.json" do
  source mcp_erb
  user node[:user] if node[:user]
  mode '0644'
end

# Rust settings
dotfile '.cargo/config.toml'

# GCloud settings
dotfile '.config/boto'

# Zsh settings
case node[:platform]
when 'darwin'
  dotfile '.zshrc.darwin'
else
  dotfile '.zshrc.Linux'
end
dotfile '.config/sheldon'
dotfile '.zsh'
dotfile '.zshrc'

# Git settings
dotfile '.gitconfig' do
  not_if 'test -f ~/.gitconfig'
end
dotfile '.gitignore_global' do
  not_if 'test -f ~/.gitignore_global'
end
