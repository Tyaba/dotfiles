case node[:platform]
when 'darwin'
  # /Applications/Aqua Voice.app の有無で判定すると、Caskroom に記録が残ったまま
  # app だけ手動削除されたケースで brew が upgrade 扱いになり置換元が無くて失敗する。
  # Caskroom 登録の有無で判定する。
  execute 'brew install --cask aqua-voice' do
    not_if 'brew list --cask aqua-voice >/dev/null 2>&1'
  end
else
  raise NotImplementedError
end
