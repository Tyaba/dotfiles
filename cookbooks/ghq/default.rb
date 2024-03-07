execute 'install ghq' do
    command 'asdf plugin add ghq && asdf install ghq latest && asdf global ghq latest'
    not_if 'asdf plugin list | grep ghq'
    # $REMOTE_CONTAINERがtrueの場合は実行しない
    not_if 'echo $REMOTE_CONTAINER'
end
