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

# Configure dotfiles
# Claude settings
dotfile '.config/claude/settings.json' => '.claude/settings.json'


# MCP settings (template with environment variable support)
# Remove existing symlink if it exists
execute "rm -f #{ENV['HOME']}/.mcp.json" do
  only_if "test -L #{ENV['HOME']}/.mcp.json"
end
template "#{ENV['HOME']}/.mcp.json" do
  source File.join(root_dir, 'config/.mcp.json.erb')
  user node[:user]
  mode '0644'
end

# Cursor MCP settings
directory "#{ENV['HOME']}/.cursor" do
  user node[:user]
end
# Remove existing symlink if it exists
execute "rm -f #{ENV['HOME']}/.cursor/mcp.json" do
  only_if "test -L #{ENV['HOME']}/.cursor/mcp.json"
end
template "#{ENV['HOME']}/.cursor/mcp.json" do
  source File.join(root_dir, 'config/.mcp.json.erb')
  user node[:user]
  mode '0644'
end

# Cursor rules
dotfile '.cursor/rules'
dotfile '.cursor/agents'
dotfile '.cursor/hooks.json'

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
