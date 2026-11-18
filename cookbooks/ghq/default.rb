mise = "#{ENV['HOME']}/.local/bin/mise"

# mitamae runs as root without ~/.local/bin on PATH, so call mise by its full path.
execute 'install ghq' do
    command <<-EOF
        #{mise} plugin install ghq https://github.com/kajisha/asdf-ghq.git
        #{mise} install ghq@latest
        #{mise} use --global ghq@latest
    EOF
    user node[:user] if node[:user]
    not_if "#{mise} ls | grep ghq"
end
