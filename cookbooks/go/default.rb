package "golang"
execute "get dlv" do
    command "go install -v github.com/go-delve/delve/cmd/dlv@latest"
    not_if 'which dlv'
end