case node[:platform]
when 'darwin'
  execute 'install brew' do
    command '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    not_if 'which brew'
  end
else
  raise NotImplementedError
end
