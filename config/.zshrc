source ~/.zsh/lib/vscode_settings
fpath+=~/.zfunc
autoload -Uz compinit && compinit

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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# "_zsh_highlight_call_widget:2: closing brace expected"対策
unsetopt sh_word_split
