execute 'install ghq' do
    command <<-EOF
        asdf plugin add ghq
        asdf install ghq latest
        asdf global ghq latest
    EOF
    not_if 'asdf plugin list | grep ghq'
    # $REMOTE_CONTAINERSがtrueの場合は実行しない
    only_if 'test -z $REMOTE_CONTAINERS'
end
