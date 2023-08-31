package 'bat'

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# bat replaces cat
alias cat="bat"
EOF
''' do
  not_if 'grep bat ~/.zsh/lib/aliases.zsh'
end
