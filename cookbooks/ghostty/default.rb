case node[:platform]
when 'darwin'
  execute 'brew install --cask ghostty' do
    not_if 'test -d /Applications/Ghostty.app'
  end
else
  raise NotImplementedError
end
