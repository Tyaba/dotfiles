case node[:platform]
when 'darwin'
  execute 'brew install --cask chatgpt' do
    not_if 'brew list --cask chatgpt >/dev/null 2>&1'
  end
else
  raise NotImplementedError
end
