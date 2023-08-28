case node[:platform]
when 'darwin'
  execute 'brew install emacs' do
    not_if 'which emacs'
  end
when 'ubuntu'
  execute 'sudo apt install -y emacs' do
    not_if 'which emacs'
  end
else
  raise NotImplementedError
end
