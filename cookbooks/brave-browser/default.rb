case node[:platform]
when 'darwin'
  execute 'brew install --cask brave-browser' do
    not_if 'test -d /Applications/Brave\ Browser.app/'
  end
else
  raise NotImplementedError
end
