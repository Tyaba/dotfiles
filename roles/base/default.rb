if run_command('test -d /etc/systemd', error: false).exit_status == 0
  [
    "#{ENV['HOME']}/.config",
    "#{ENV['HOME']}/.config/systemd",
    "#{ENV['HOME']}/.config/systemd/user",
  ].each do |dir|
    directory dir do
      owner node[:user]
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

# Cursor-specific
dotfile '.cursor/rules' => 'coding_agents/cursor/rules'
dotfile '.cursor/hooks.json' => 'coding_agents/cursor/hooks.json'

# Claude Code-specific
dotfile '.claude/CLAUDE.md' => 'coding_agents/claude/CLAUDE.md'
dotfile '.claude/settings.json' => 'coding_agents/claude/settings.json'

# MCP settings (template generates both Cursor and Claude Code configs)
mcp_erb = File.join(root_dir, 'config/coding_agents/mcp.json.erb')

directory "#{ENV['HOME']}/.cursor" do
  user node[:user]
end

execute "rm -f #{ENV['HOME']}/.mcp.json" do
  only_if "test -L #{ENV['HOME']}/.mcp.json"
end
template "#{ENV['HOME']}/.mcp.json" do
  source mcp_erb
  user node[:user]
  mode '0644'
end

execute "rm -f #{ENV['HOME']}/.cursor/mcp.json" do
  only_if "test -L #{ENV['HOME']}/.cursor/mcp.json"
end
template "#{ENV['HOME']}/.cursor/mcp.json" do
  source mcp_erb
  user node[:user]
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
