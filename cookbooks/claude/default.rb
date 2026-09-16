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

# Official Codex plugin for Claude Code (openai/codex-plugin-cc), the upstream
# replacement for the `codex mcp-server` entry that codex 0.154.0 deleted. It
# drives `codex app-server` and adds the /codex:review family plus a
# codex-rescue subagent.
#
# This cookbook is host-only (included from roles/darwin and roles/ubuntu), and
# that is deliberate: the plugin hardcodes its sandbox as workspace-write for
# write tasks and ignores $CODEX_HOME/config.toml, so in the devcontainer --
# which has no unprivileged user namespaces -- every shell call it makes dies
# in bwrap and it reports success without editing anything. Both host and
# container offload through the codex-offload subagent (`codex exec`) instead,
# which does honour config.toml.
#
# Runs after roles/base has rendered ~/.claude/settings.json: `claude plugin
# install` merges enabledPlugins / extraKnownMarketplaces into that file. Those
# keys are declared in settings.json.erb too, so a later re-render keeps them.
# The CLI still has to run, because marketplace and install state live outside
# settings.json in ~/.claude/plugins/*.json, which dotfiles does not manage.
execute 'add openai codex plugin marketplace' do
  command '$HOME/.local/bin/claude plugin marketplace add openai/codex-plugin-cc'
  not_if '$HOME/.local/bin/claude plugin marketplace list 2>/dev/null | grep -q openai-codex'
end

execute 'install claude plugin codex' do
  command '$HOME/.local/bin/claude plugin install codex@openai-codex --scope user'
  not_if '$HOME/.local/bin/claude plugin list 2>/dev/null | grep -q codex@openai-codex'
end

# Codex CLI itself is installed by the mise npm backend declared in
# config/mise/config.toml.erb, not here. A plain `npm install -g` was fragile:
# npm globals are per-node-version, so a node bump (e.g. 20 -> 24) orphaned
# codex while the leftover mise shim let `not_if 'which codex'` skip the
# reinstall, leaving the CLI dead. mise pins codex independently of the active
# node, surviving node upgrades.
