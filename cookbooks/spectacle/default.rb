case node[:platform]
when 'darwin'
  execute 'brew install --cask spectacle' do
    not_if 'test -d /Applications/Spectacle.app'
  end
else
  raise NotImplementedError
end
