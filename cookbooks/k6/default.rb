case node[:platform]
when 'darwin'
    package "k6"
when node[:platform] == 'ubuntu', 'debian'
    execute "install k6" do
        command <<-EOF
            mkdir -p /tmp/k6
            wget -O /tmp/k6/k6.tar.gz https://github.com/grafana/xk6-dashboard/releases/download/v0.7.4/xk6-dashboard_v0.7.4_linux_amd64.tar.gz
            tar -xzf /tmp/k6/k6.tar.gz -C /tmp/k6
            mv /tmp/k6/k6 /usr/bin/k6
        EOF
        not_if "which k6"
    end
else
    raise NotImplementedError
end
