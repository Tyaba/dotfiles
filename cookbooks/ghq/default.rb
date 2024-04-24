execute 'install ghq' do
    command <<-EOF
        mise install ghq@latest
        mise use --global ghq@latest
    EOF
    not_if 'mise ls | grep ghq'
end
