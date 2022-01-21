case node[:platform]
when 'darwin'
  execute 'brew tap tldr-pages/tldr && brew install tldr' do
    not_if 'which tldr'
  end
when 'ubuntu'
  execute 'sudo apt install -y tldr' do
    not_if 'which tldr'
  end
else
  raise NotImplementedError
end
