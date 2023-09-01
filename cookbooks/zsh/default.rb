case node[:platform]
when 'darwin'
  dotfile '.zshrc.darwin'
  execute "sudo chsh -s /bin/zsh #{node[:user]}" do
    not_if 'test $SHELL == /bin/zsh'
  end
else
  package 'zsh'
  dotfile '.zshrc.Linux'
  execute "chsh -s /bin/zsh #{node[:user]}" do
    not_if 'test $SHELL == /bin/zsh'
    only_if "getent passwd #{node[:user]} | cut -d: -f7 | grep -q '^/bin/bash$'"
    user 'root'
  end
end

# zplug
execute "curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh && sudo chown -R #{node[:user]}:#{node[:user]} ~/.zplug" do
  not_if 'test -d ~/.zplug'
end
dotfile '.zsh'
dotfile '.zshrc'
