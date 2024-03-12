case node[:platform]
when 'darwin'
  execute 'brew install --cask vivaldi' do
    not_if 'test -d /Applications/Vivaldi.app'
  end
else
  raise NotImplementedError
end
