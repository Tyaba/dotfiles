proxy_dir = "#{ENV['HOME']}/.tyaba/proxy"
certs_dir = "#{proxy_dir}/certs"

# レシピファイル基準で files/ を解決する。Dir.pwd だと install.sh 経由以外の
# 起動方法（別 cwd から mitamae を直接叩く等）で壊れるため __FILE__ を使う。
# `remote_file` を使わない理由: AD 連携 macOS（CyberAgent 管理機等）では
# mitamae の chown 実装が getgrgid に失敗して 'UNKNOWN' 文字列を渡し、
# `chown s17536:UNKNOWN` が 'illegal group name' で確実に失敗するため。
files_dir = File.join(File.dirname(__FILE__), 'files')

case node[:platform]
when 'darwin'
  execute "mkdir -p #{certs_dir}" do
    not_if "test -d #{certs_dir}"
  end

  execute "install -m 0644 #{files_dir}/docker-compose.yaml #{proxy_dir}/docker-compose.yaml" do
    not_if "cmp -s #{files_dir}/docker-compose.yaml #{proxy_dir}/docker-compose.yaml"
  end

  execute "install -m 0644 #{files_dir}/traefik.yaml #{proxy_dir}/traefik.yaml" do
    not_if "cmp -s #{files_dir}/traefik.yaml #{proxy_dir}/traefik.yaml"
  end

  execute 'generate mkcert wildcard certificate for .test' do
    # mkcert は単一ラベル wildcard のみサポート (*.*.test は不可)。
    # tyaba-env 側で fullstack は <slug>-frontend.test / <slug>-backend.test の命名に揃え、
    # single-service は <slug>.test を使う。すべて *.test 単一 wildcard でカバー。
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
