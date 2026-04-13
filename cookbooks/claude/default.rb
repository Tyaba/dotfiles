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

# LSP binaries for Claude Code plugins
execute 'install typescript-language-server' do
  command 'npm install -g typescript-language-server typescript'
  not_if 'which typescript-language-server'
end

execute 'install pyright' do
  command 'uv tool install pyright'
  not_if 'which pyright-langserver'
end

# Claude Code LSP plugins (user scope)
%w[typescript-lsp pyright-lsp].each do |plugin|
  execute "install claude plugin #{plugin}" do
    command "claude plugin install #{plugin}@claude-plugins-official --scope user"
    not_if "claude plugin list 2>/dev/null | grep -q #{plugin}"
  end
end
