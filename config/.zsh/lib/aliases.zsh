alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias g="git"
alias s="git status -sb"

# replace
alias git="hub"
# bat replaces cat
alias cat="bat"
# rip grep replaces grep
alias grep="rg"
# exa replaces ls
alias ls="exa -a"
# procs replaces ps
alias ps="procs"
# fd replaces find
alias find="fd"
# bottom replaces top
alias top="btm"

# in short
# lazydocker
alias lzd="lazydocker"
# kubernetes
source <(kubectl completion zsh)
alias k=kubectl
# terraform
alias tf="terraform"
# gcloud
alias gcurl='curl --header "Authorization: Bearer $(gcloud auth print-identity-token)"'
# Docker
alias d=docker
# dust replaces du
alias du="dust"
# cargo-script
alias rust="cargo-script"
