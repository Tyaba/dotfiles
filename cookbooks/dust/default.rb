package 'dust'

execute '''cat <<EOF >> ~/.zsh/lib/aliases
# dust replaces du
alias du="dust"
EOF
''' do
  not_if 'grep dust ~/.zsh/lib/aliases'
end
