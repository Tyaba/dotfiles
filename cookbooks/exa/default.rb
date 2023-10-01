package 'exa'

execute '''cat <<EOF >> ~/.zsh/lib/aliases
# exa replaces ls
alias ls="exa"
EOF
''' do
  not_if 'grep exa ~/.zsh/lib/aliases'
end
