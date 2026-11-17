# Install the Claude Code CLI binary only.
#
# Roles include this cookbook first, before `include_role 'base'`, so that a
# usable `claude` exists as early as possible: if a later cookbook breaks
# provisioning, the half-provisioned machine can still be troubleshot with
# Claude Code. The native installer needs only curl, which bin/setup already
# requires for fetching mitamae.
#
# Installing before roles/base also lets base's sync-claude-user-mcp.sh find
# `claude` on the first run instead of skipping the MCP sync.
#
# Plugins and LSP binaries depend on npm / uv and on the rendered
# ~/.claude/settings.json, so they stay in cookbooks/claude, which includes this
# cookbook (mitamae includes a recipe only once).
#
# On Linux install.sh runs mitamae via `sudo -E`, so resources run as root
# unless they set `user`. The installer refuses to run as root under sudo
# (uid 0 with SUDO_USER set) because it would install into root's home.
# `user node[:user]` makes mitamae wrap the command (and its not_if guard) in
# `sudo -H -u <user>`, so $HOME and ownership belong to the login user.
case node[:platform]
when 'darwin', 'ubuntu', 'debian'
  execute 'install claude code' do
    command 'curl -fsSL https://claude.ai/install.sh | bash'
    not_if 'test -f $HOME/.local/bin/claude'
    user node[:user] if node[:user]
  end
else
  raise NotImplementedError
end
