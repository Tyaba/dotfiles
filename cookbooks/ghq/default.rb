execute 'install ghq' do
    command <<-EOF
        asdf plugin add ghq
        asdf install ghq latest
        asdf global ghq latest
    EOF
    not_if 'asdf plugin list | grep ghq'
end
