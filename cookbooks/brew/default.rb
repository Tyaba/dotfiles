case node[:platform]
when 'darwin'
  execute 'install brew' do
    command 'NONINTERACTIVE=1 /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    not_if 'which brew'
  end
else
  raise NotImplementedError
end
