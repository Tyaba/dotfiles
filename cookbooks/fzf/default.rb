execute "git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf && $HOME/.fzf/install --all" do
    not_if 'test -d $HOME/.fzf'
    end