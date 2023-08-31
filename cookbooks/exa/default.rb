package 'exa'

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# exa replaces ls
alias ls="exa -a"
EOF
''' do
  not_if 'grep exa ~/.zsh/lib/aliases.zsh'
end
