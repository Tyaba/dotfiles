package 'bottom'

execute '''cat <<EOF >> ~/.zsh/lib/aliases
# bottom replaces top
alias top="btm"
EOF
''' do
  not_if 'grep btm ~/.zsh/lib/aliases'
end
