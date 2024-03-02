include_role 'base'
dotfile ".tmux.conf"
dotfile '.zsh'
include_cookbook 'darwin_base'
include_cookbook 'brew'
# mac GUI tools
include_cookbook 'mas'
include_cookbook 'bitwarden'
include_cookbook 'discord'
include_cookbook 'line'
include_cookbook 'scroll-reverser'
include_cookbook 'slack'
include_cookbook 'spectacle'
include_cookbook 'vivaldi'
include_cookbook 'vlc'
include_cookbook 'zoom'
## 状況把握
include_cookbook 'htop'
include_cookbook 'visual-studio-code'
include_cookbook 'karabiner-elements'
include_cookbook 'iterm'
include_cookbook 'spectacle'
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
include_cookbook 'emacs'
include_cookbook 'ghq'
include_cookbook 'gh'
include_cookbook 'docker'
include_cookbook 'gcloud'
include_cookbook 'poetry'
# 代替系
include_cookbook 'ripgrep'
include_cookbook 'tldr'
# 便利系
include_cookbook 'gibo'
include_cookbook 'watch'
include_cookbook 'tree'
include_cookbook 'nkf'
include_cookbook 'procs'
include_cookbook 'fd'
# 便利系
include_cookbook 'tokei'
include_cookbook 'ncdu'
# mac CLI tools
include_cookbook 'gnu-sed'
