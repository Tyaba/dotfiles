# sheldon
## oh my zsh
export ZSH="$HOME/.local/share/sheldon/repos/github.com/ohmyzsh/ohmyzsh"
ZSH_THEME="jonathan"
## enhancd: cd -> ls
export ENHANCD_HOOK_AFTER_CD=ls
# sheldon 設定を読み込む
eval "$(sheldon source)"
