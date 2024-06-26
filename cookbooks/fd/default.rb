execute "cargo install fd-find" do
  not_if "which fd"
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases
# fd replaces find
alias find="fd"
EOF
''' do
  not_if 'grep fd ~/.zsh/lib/aliases'
end
