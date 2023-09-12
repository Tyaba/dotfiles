source ~/.zsh/lib/plugins
source ~/.zsh/lib/basic
source ~/.zsh/lib/aliases
source ~/.zsh/lib/completion
source ~/.zsh/lib/functions
source ~/.zsh/lib/languages
source ~/.zsh/lib/apps

# Environment-local configurations
if [ -f ~/.zshrc.`uname` ]; then source ~/.zshrc.`uname`; fi
if [ -f ~/.zshrc.local ]; then source ~/.zshrc.local; fi

fpath+=~/.zfunc
autoload -Uz compinit && compinit

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
