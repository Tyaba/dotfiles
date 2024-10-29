case node[:platform]
when 'darwin'
  execute 'brew install --cask cursor' do
    not_if 'which cursor'
  end
else
  raise NotImplementedError
end
