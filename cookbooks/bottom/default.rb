package 'bottom'

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# bottom replaces top
alias top="btm"
EOF
''' do
  not_if 'grep btm ~/.zsh/lib/aliases.zsh'
end
