proxy_dir = "#{ENV['HOME']}/.tyaba/proxy"
certs_dir = "#{proxy_dir}/certs"

case node[:platform]
when 'darwin'
  directory proxy_dir do
    owner node[:user] if node[:user]
    group node[:group] if node[:group]
    mode '0755'
  end

  directory certs_dir do
    owner node[:user] if node[:user]
    group node[:group] if node[:group]
    mode '0755'
  end

  remote_file "#{proxy_dir}/docker-compose.yaml" do
    source 'docker-compose.yaml'
    owner node[:user] if node[:user]
    group node[:group] if node[:group]
    mode '0644'
  end

  remote_file "#{proxy_dir}/traefik.yaml" do
    source 'traefik.yaml'
    owner node[:user] if node[:user]
    group node[:group] if node[:group]
    mode '0644'
  end

  execute 'generate mkcert wildcard certificate for .test' do
    command "cd #{certs_dir} && mkcert -cert-file _wildcard.test.pem -key-file _wildcard.test-key.pem \"*.test\" test"
    not_if "test -f #{certs_dir}/_wildcard.test.pem"
  end

  execute 'docker network create tyaba-proxy' do
    not_if 'docker network inspect tyaba-proxy >/dev/null 2>&1'
  end

  execute 'docker compose up tyaba proxy' do
    command "docker compose -f #{proxy_dir}/docker-compose.yaml up -d"
    not_if "docker ps --filter 'name=tyaba-proxy-traefik' --filter 'status=running' --format '{{.Names}}' | grep -q traefik"
  end
else
  raise NotImplementedError
end
