include_role 'base'
dotfile ".tmux.conf"
dotfile '.zsh'

## 状況把握
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
include_cookbook 'emacs'
include_cookbook 'docker'
include_cookbook 'gcloud'
include_cookbook 'poetry'
# 代替系
include_cookbook 'ripgrep'
include_cookbook 'hub'
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
# mac固有
include_cookbook 'gnu-sed'
include_cookbook 'karabiner-elements'