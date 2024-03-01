case node[:platform]
when 'darwin'
  package 'karabiner-elements'
  # karabiner-elementsの設定ファイルをリンクする
  execute 'mkdir -p $HOME/.config'
  execute 'ln -sf $HOME/.dotfiles/config/.config/karabiner/ $HOME/.config/'
else
  raise NotImplementedError
end
