case node[:platform]
when 'darwin'
  execute 'brew install --cask cursor' do
    not_if 'which cursor'
  end

  execute 'brew install --cask cursor-cli' do
    not_if 'which agent'
  end
else
  raise NotImplementedError
end
