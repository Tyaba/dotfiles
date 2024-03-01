case node[:platform]
when 'darwin'
  execute 'brew install --cask bitwarden' do
    not_if 'test -d /Applications/Bitwarden.app'
  end
else
  raise NotImplementedError
end
