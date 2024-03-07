case node[:platform]
    when 'darwin'
        package 'gh'
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