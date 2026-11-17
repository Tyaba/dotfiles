include_recipe 'recipe_helper'

# On Linux install.sh runs mitamae via `sudo -E`, and sudo can still reset
# HOME to root's home (e.g. /root) despite -E. Every recipe resolves dotfile
# and config paths from ENV['HOME'], so restore the invoking user's home
# before any role is evaluated. Setting ENV here also propagates to the
# commands mitamae spawns, so `$HOME` inside execute resources matches.
sudo_user = ENV['SUDO_USER']
if ENV['DOTFILES_ROLE'] != 'devcontainer' && sudo_user && !sudo_user.empty? && sudo_user != 'root'
  sudo_home = run_command("getent passwd #{sudo_user}", error: false).stdout.split(':')[5].to_s.strip
  ENV['HOME'] = sudo_home unless sudo_home.empty?
end

# DOTFILES_ROLE=devcontainer runs mitamae as the workspace user (no sudo).
# Leave node[:user]/node[:group] nil so resources don't pass a `user`
# attribute — mitamae unconditionally wraps `user X` with `sudo -H -u X`,
# which fails in devcontainers where the workspace user is not in sudoers.
# In that mode, resources run as the current process user, which is already
# the correct owner.
if ENV['DOTFILES_ROLE'] == 'devcontainer'
  node.reverse_merge!(user: nil, group: nil)
else
  node.reverse_merge!(
    user: ENV['SUDO_USER'] || ENV['USER'],
    group: ENV['GROUP']
  )
end
case node[:platform]
when 'ubuntu', 'debian'
  node.reverse_merge!(
    codename: run_command('lsb_release -cs').stdout.strip,
  )
when 'darwin'
  # intel macか判定
  # 'x86_64' -> Intel Mac
  # 'arm64' -> M1 Mac
  node.reverse_merge!(
    architecture: `uname -m`.chomp
  )
end

include_role(ENV['DOTFILES_ROLE'] || node[:platform])
