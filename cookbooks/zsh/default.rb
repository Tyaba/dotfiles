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
# sheldon (zsh plugin manager)
execute "cargo install sheldon" do
  not_if "which sheldon"
end
dotfile '.config/sheldon'
dotfile '.zsh'
dotfile '.zshrc'
