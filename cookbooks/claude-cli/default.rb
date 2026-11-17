# Install the Claude Code CLI binary only.
#
# Host roles (roles/darwin, roles/ubuntu) include this cookbook right after
# `include_role 'base'`, ahead of the other cookbooks, so that a usable
# `claude` exists early: if a later cookbook breaks provisioning, the
# half-provisioned machine can still be troubleshot with Claude Code. The
# native installer needs only curl, which bin/setup already requires for
# fetching mitamae. roles/devcontainer does not use this cookbook; it installs
# claude through mise's npm backend instead.
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
