execute 'install ghq' do
    command <<-EOF
        mise plugin install ghq https://github.com/kajisha/asdf-ghq.git
        mise install ghq@latest
        mise use --global ghq@latest
    EOF
    not_if 'mise ls | grep ghq'
end
