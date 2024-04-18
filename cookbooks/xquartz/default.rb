case node[:platform]
when 'darwin'
  execute 'brew install --cask xquartz' do
    not_if 'test -d /Applications/Utilities/XQuartz.app'
  end
else
  raise NotImplementedError
end