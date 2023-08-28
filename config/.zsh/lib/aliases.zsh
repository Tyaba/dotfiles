alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias g="git"
alias s="git status -sb"

# bat replaces cat
alias cat="bat"
# exa replaces ls
alias ls="exa -a"
# procs replaces ps
alias ps="procs"
# lazydocker
alias lzd="lazydocker"
# kubernetes
source <(kubectl completion zsh)
alias k=kubectl
# fd replaces find
alias find="fd"
# terraform
alias tf="terraform"
# gcloud
alias gcurl='curl --header "Authorization: Bearer $(gcloud auth print-identity-token)"'
# Docker
alias d=docker
# dust replaces du
alias du="dust"
# bottom replaces top
alias top="btm"
