package 'exa'

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# exa replaces ls
alias ls="exa"
EOF
''' do
  not_if 'grep exa ~/.zsh/lib/aliases.zsh'
end
