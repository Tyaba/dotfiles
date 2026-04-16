# Install Claude Code CLI
case node[:platform]
when 'darwin', 'ubuntu', 'debian'
  execute 'install claude code' do
    command 'curl -fsSL https://claude.ai/install.sh | bash'
    not_if 'test -f $HOME/.local/bin/claude'
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
  command '$HOME/.local/bin/uv tool install pyright'
  not_if 'which pyright-langserver'
end

# Claude Code LSP plugins (user scope)
%w[typescript-lsp pyright-lsp].each do |plugin|
  execute "install claude plugin #{plugin}" do
    command "$HOME/.local/bin/claude plugin install #{plugin}@claude-plugins-official --scope user"
    not_if "$HOME/.local/bin/claude plugin list 2>/dev/null | grep -q #{plugin}"
  end
end

# Codex CLI for codex-plugin-cc
execute 'install codex cli' do
  command 'npm install -g @openai/codex'
  not_if 'which codex'
end

# codex-plugin-cc (Claude Code plugin)
execute 'add codex plugin marketplace' do
  command "$HOME/.local/bin/claude plugin marketplace add openai/codex-plugin-cc"
  not_if "$HOME/.local/bin/claude plugin list 2>/dev/null | grep -q codex"
end

execute 'install codex plugin' do
  command "$HOME/.local/bin/claude plugin install codex@openai-codex --scope user"
  not_if "$HOME/.local/bin/claude plugin list 2>/dev/null | grep -q codex"
end
