case node[:platform]
when 'darwin'
  package 'karabiner-elements'
  # karabiner-elementsの設定ファイルをリンクする
  execute 'mkdir -p $HOME/.config' do
    not_if 'test -d $HOME/.config'
  end
  execute 'ln -sf $HOME/.dotfiles/config/.config/karabiner/ $HOME/.config/' do
    not_if 'test -d $HOME/.config/karabiner'
  end
else
  raise NotImplementedError
end
