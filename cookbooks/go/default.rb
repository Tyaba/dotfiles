case node['platform']
when 'debian', 'ubuntu'
    package "golang"
when 'darwin'
    package "go"
else
    raise NotImplementedError
end

# TODO: golangとdlvのversion compatibilityの問題でdlv latestは取れない。
# golangをversion指定して取るか、
# execute "get dlv" do
#     command "go install -v github.com/go-delve/delve/cmd/dlv@v1.23.0"
#     not_if 'which dlv'
# end