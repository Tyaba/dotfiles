case node[:platform]
    when 'darwin'
        package 'gh'

        root_dir = File.expand_path('../../..', __FILE__)
        shims_dir = "#{ENV['HOME']}/.local/share/dotfiles/shims"

        directory shims_dir do
            user node[:user] if node[:user]
        end

        link "#{shims_dir}/gh" do
            to File.join(root_dir, 'config/shims/gh')
        end

        gh_dir = "#{ENV["HOME"]}/.config/gh"
        gh_hosts_file = "#{gh_dir}/hosts.yml"

        execute 'restrict gh config directory permissions' do
            command "chmod 0700 \"#{gh_dir}\""
            only_if "test -d \"#{gh_dir}\""
            not_if "test \"$(stat -f %Lp \"#{gh_dir}\")\" = 700"
        end

        execute 'restrict gh credentials file permissions' do
            command "chmod 0600 \"#{gh_hosts_file}\""
            only_if "test -f \"#{gh_hosts_file}\""
            not_if "test \"$(stat -f %Lp \"#{gh_hosts_file}\")\" = 600"
        end
    when 'ubuntu', 'debian'
        execute 'install gh' do
            command '''sudo mkdir -p -m 755 /etc/apt/keyrings && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
            && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
            && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
            && sudo apt update \
            && sudo apt install gh -y'''
            # `which gh` also matches a mise shim that has no version set.
            not_if 'test -x /usr/bin/gh'
        end
    else
        raise NotImplementedError
end

if ENV['REMOTE_CONTAINERS'] then
    MItamae.logger.info('devcontainerを検知 gh-qのインストールをスキップします')
else
    MItamae.logger.info("devcontainerではないです。gh-qをインストールします")
    # use gh-q
    # Bypass the mise shim on Linux, and keep ~/.local/share/gh owned by the login user.
    gh_command = node[:platform] == 'darwin' ? 'gh' : '/usr/bin/gh'
    execute 'gh extension install kawarimidoll/gh-q' do
        command "#{gh_command} extension install kawarimidoll/gh-q"
        user node[:user] if node[:user]
        # `gh extension list` requires authentication; the install itself does not.
        not_if "test -d #{ENV['HOME']}/.local/share/gh/extensions/gh-q"
    end
end
