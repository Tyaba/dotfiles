case node[:platform]
when 'darwin'
  execute 'install brew' do
    command 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    not_if 'which brew'
  end
  execute 'brew update' do
    command 'brew update'
else
  raise NotImplementedError
end
