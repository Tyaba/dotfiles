execute 'install ghq' do
    command <<-EOF
        asdf plugin add ghq
        asdf install ghq latest
        asdf global ghq latest
    EOF
    not_if 'asdf plugin list | grep ghq'
    # $REMOTE_CONTAINERSがtrueの場合は実行しない
    not_if 'echo $REMOTE_CONTAINERS'
end
