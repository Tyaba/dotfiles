package lazydocker

execute '''cat <<EOF >> ~/.zsh/lib/aliases
# lazydocker
alias lzd="lazydocker"
EOF
''' do
  not_if 'grep lazydocker ~/.zsh/lib/aliases'
end
