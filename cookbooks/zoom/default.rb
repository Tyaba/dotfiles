case node[:platform]
when 'darwin'
  execute 'brew install --cask zoom' do
    not_if 'test -d /Applications/zoom.us.app'
  end
else
  raise NotImplementedError
end
