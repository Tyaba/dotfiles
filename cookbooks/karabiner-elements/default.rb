case node[:platform]
when 'darwin'
  package 'karabiner-elements'
  # karabiner-elementsの設定ファイルをリンクする
  execute 'mkdir -p $HOME/.config' do
    not_if 'test -d $HOME/.config'
  execute 'ln -sf $HOME/.dotfiles/config/.config/karabiner/ $HOME/.config/' do
    not_if 'test -d $HOME/.config/karabiner'
else
  raise NotImplementedError
end
