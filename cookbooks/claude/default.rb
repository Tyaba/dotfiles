# Install Claude Code CLI
case node[:platform]
when 'darwin', 'ubuntu', 'debian'
  execute 'install claude code' do
    command 'curl -fsSL https://claude.ai/install.sh | bash'
    not_if 'which claude'
  end
else
  raise NotImplementedError
end

# Configure Claude settings
dotfile '.config/claude/settings.json' => '.claude/settings.json'
