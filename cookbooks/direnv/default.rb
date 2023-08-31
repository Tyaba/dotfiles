package 'direnv'
execute '''cat <<EOF >> ~/.zsh/lib/apps.zsh
# direnv
export EDITOR=emacs
eval "$(direnv hook zsh)"
EOF
''' do
    not_if 'grep direnv ~/.zsh/lib/apps.zsh'
  end