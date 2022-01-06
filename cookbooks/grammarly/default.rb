case node[:platform]
when 'darwin'
  execute 'brew install --cask grammarly' do
    not_if 'test -d /Applications/Grammarly\ Editor.app'
  end
else
  raise NotImplementedError
end
