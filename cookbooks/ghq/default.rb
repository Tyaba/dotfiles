execute 'install ghq' do
    command 'asdf plugin add ghq && asdf install ghq latest && asdf global ghq latest'
    not_if 'asdf plugin list | grep ghq'
    end