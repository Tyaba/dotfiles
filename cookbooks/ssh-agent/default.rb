# このレシピは、ssh-agentの設定ファイルを配置する
# systemdについて：参考URL
# https://wiki.archlinux.jp/index.php/Systemd/%E3%83%A6%E3%83%BC%E3%82%B6%E3%83%BC
# ~/.config/systemd/userはユーザが配置する、そのユーザのサービス
remote_file "#{ENV['HOME']}/.config/systemd/user/ssh-agent.service" do
    source 'files/ssh-agent.service'
    owner node[:user]
    group node[:user]
end
# systemdのユーザインスタンスの環境変数は.bashrcなどの設定を継承しない。.pam-environmentに設定する
remote_file "#{ENV['HOME']}/.pam-environment" do
    source 'files/.pam-environment'
end

# default.target.wantsからユーザ定義サービスへのssh-agent.serviceのシンボリックリンクを作成する
link "#{ENV['HOME']}/.config/systemd/user/default.target.wants/ssh-agent.service" do
    to "#{ENV['HOME']}/.config/systemd/user/ssh-agent.service"
end

user_service 'ssh-agent' do
    action :start
end