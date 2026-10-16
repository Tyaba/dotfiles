case node[:platform]
    when 'darwin'
        package 'gh'

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
            not_if 'which gh'
        end
    else
        raise NotImplementedError
end

if ENV['REMOTE_CONTAINERS'] then
    MItamae.logger.info('devcontainerを検知 gh-qのインストールをスキップします')
else
    MItamae.logger.info("devcontainerではないです。gh-qをインストールします")
    # use gh-q
    execute 'gh extension install kawarimidoll/gh-q' do
        not_if 'gh extension list | grep gh-q'
    end
end
