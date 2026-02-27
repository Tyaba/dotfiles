case node[:platform]
when 'darwin'
  execute 'brew install --cask raycast' do
    not_if 'test -d /Applications/Raycast.app'
  end

  plist = File.expand_path('../../config/.config/com.raycast.macos.plist', File.dirname(__FILE__))
  if File.exist?(plist)
    execute "defaults import com.raycast.macos #{plist}" do
      not_if 'defaults read com.raycast.macos raycastGlobalHotkey 2>/dev/null'
    end
  end
else
  raise NotImplementedError
end
