# このレシピは、gpg-agentをインストールし、設定ファイルを配置する
# gnupg-agentをinstall
package 'gnupg-agent'
# sudoで作られた~/.gnupgのownerをユーザに変更
directory "#{ENV['HOME']}/.gnupg" do
    owner node[:user]
    group node[:user]
end
# files/gpg-agent.confを~/.gnupg/gpg-agent.confに配置
remote_file "#{ENV['HOME']}/.gnupg/gpg-agent.conf" do
    source 'files/gpg-agent.conf'
    owner node[:user]
    group node[:user]
end

file '/usr/lib/systemd/user/gpg-agent.service' do
    action :edit
    block do |content|
        unless content.include?('[Install]')
            content.gsub!(/\z/, "\n[Install]\nWantedBy=default.target\n")
        end
    end
end

user_service 'gpg-agent' do
    action [:start, :enable]
end

user_service 'gpg-agent.socket' do
    action [:start, :enable]
end