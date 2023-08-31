source ~/.zplug/init.zsh
# 1
zplug "themes/wedisagree", from:oh-my-zsh, as:theme, if:"[[ $OSTYPE == *darwin* ]]"
zplug "themes/blinks", from:oh-my-zsh, as:theme, if:"[[ $OSTYPE == *linux* ]]"
zplug "junegunn/fzf", as:command, from:gh-r
zplug "b4b4r07/enhancd", use:init.sh
# Load "emoji-cli" if "jq" is installed
zplug "stedolan/jq", from:gh-r, as:command, rename-to:jq
zplug "b4b4r07/emoji-cli", on:"stedolan/jq"

# (If the defer tag is given 2 or above, run after compinit command)
zplug "zsh-users/zsh-autosuggestions", defer:2
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-completions", defer:2
zplug "zsh-users/zsh-history-substring-search", hook-build:"__zsh_version 5.3", defer:2

zplug check || zplug install
zplug load

plugins=(git history history-substring-search mysql ruby rails gem brew rake zsh-completions kubectl)

export ENHANCD_HOOK_AFTER_CD=ls
