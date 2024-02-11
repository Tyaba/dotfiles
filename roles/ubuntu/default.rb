# coding: utf-8
include_role 'base'
dotfile ".tmux.conf"
dotfile '.zsh'
# systemdのユーザインスタンス置き場ディレクトリ
directory "#{ENV['HOME']}/.config/systemd/user/default.target.wants" do
    owner node[:user]
    # group node[:user]
    mode '755'
end
# update
execute 'apt-get update'
# 状況把握
include_cookbook 'htop'
# 依存元
include_cookbook 'basic'
include_cookbook 'rust'
include_cookbook 'zsh'
include_cookbook 'direnv'
include_cookbook 'fzf'
include_cookbook 'git'
include_cookbook 'pipx'
include_cookbook 'asdf'
# 開発系
include_cookbook 'ripgrep'
include_cookbook 'emacs'
include_cookbook 'docker'
include_cookbook 'gcloud'
include_cookbook 'poetry'
# include_cookbook 'gpg-agent'
# include_cookbook 'ssh-agent'
# 便利系
include_cookbook 'hub'
include_cookbook 'tldr'
include_cookbook 'gibo'
include_cookbook 'watch'
include_cookbook 'tree'
include_cookbook 'nkf'
include_cookbook 'procs'
include_cookbook 'fd'
# 便利系
include_cookbook 'tokei'
include_cookbook 'ncdu'
# 必須でない開発系
include_cookbook 'redis'
