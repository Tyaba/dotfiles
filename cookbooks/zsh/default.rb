case node[:platform]
when 'darwin'
  # $SHELL reflects the invoking environment, not the OS login shell.
  # Non-interactive provisioning can inherit an unset or stale value; query
  # Directory Services for the target user's persisted login shell instead.
  # Some sandboxed macOS sessions make dscl return eServerError; keep the
  # dscacheutil fallback because a false guard can fall through to sudo chsh.
  login_shell_is_zsh = [
    "dscl . -read /Users/#{node[:user]} UserShell 2>/dev/null | grep -qxF 'UserShell: /bin/zsh'",
    "dscacheutil -q user -a name #{node[:user]} | grep -qxF 'shell: /bin/zsh'",
  ].join(' || ')

  execute "sudo chsh -s /bin/zsh #{node[:user]}" do
    not_if login_shell_is_zsh
  end
else
  package 'zsh'
  execute "chsh -s /bin/zsh #{node[:user]}" do
    only_if "getent passwd #{node[:user]} | cut -d: -f7 | grep -q '^/bin/bash$'"
    user 'root'
  end
end
# sheldon (zsh plugin manager)
execute "cargo install sheldon" do
  not_if "which sheldon"
end
