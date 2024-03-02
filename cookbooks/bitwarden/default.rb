case node[:platform]
when 'darwin'
  # brewで入れた場合はブラウザ統合が使えないので、App Storeから入れる
  execute 'install bitwarden' do
    command 'mas install 1352778147'
    not_if 'test -d /Applications/Bitwarden.app'
  end
else
  raise NotImplementedError
end
