case node[:platform]
when 'darwin'
  execute 'brew install --cask scroll-reverser' do
    not_if 'test -d /Applications/Scroll Reverser.app'
  end
else
  raise NotImplementedError
end
