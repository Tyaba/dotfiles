case node[:platform]
when 'darwin'
  package 'karabiner-elements'
  execute 'ln -sf $HOME/.dotfiles/config/.hotkey/karabiner_elements/* $HOME/.config/karabiner/assets/complex_modifications'
else
  raise NotImplementedError
end
