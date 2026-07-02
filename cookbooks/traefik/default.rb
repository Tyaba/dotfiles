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

  # Traefik v3 は tls.certificates / tls.stores を静的設定に置くと silently
  # 無視するため、動的設定として dynamic.yaml に分離して providers.file 経由で
  # ロードする。詳細は cookbooks/traefik/files/traefik.yaml のコメント参照。
  execute "install -m 0644 #{files_dir}/dynamic.yaml #{proxy_dir}/dynamic.yaml" do
    not_if "cmp -s #{files_dir}/dynamic.yaml #{proxy_dir}/dynamic.yaml"
  end

  execute 'generate mkcert wildcard certificate for .tyaba.test' do
    # Chrome / Firefox は「TLD 直下 (2 labels only)」の wildcard を
    # ERR_CERT_COMMON_NAME_INVALID で拒否するため *.test は使えない。
    # 3 labels 以上の `*.tyaba.test` に変更し、tyaba-env 側で新規プロジェクトは
    # <slug>-frontend.tyaba.test / <slug>-backend.tyaba.test / <slug>.tyaba.test
    # の命名で揃える。dnsmasq は `.test` 全体を 127.0.0.1 に返すので
    # `.tyaba.test` も追加設定なしで到達する。
    command "cd #{certs_dir} && mkcert -cert-file _wildcard.tyaba.test.pem -key-file _wildcard.tyaba.test-key.pem \"*.tyaba.test\" tyaba.test"
    not_if "test -f #{certs_dir}/_wildcard.tyaba.test.pem"
  end

  execute 'docker network create tyaba-proxy' do
    not_if 'docker network inspect tyaba-proxy >/dev/null 2>&1'
  end

  # `docker compose up -d` は idempotent。docker-compose.yaml / traefik.yaml /
  # dynamic.yaml のいずれかが変更されると Compose が差分を検知して container を
  # recreate し、新しい mount / 静的設定を反映する。無変更なら no-op なので
  # 「running なら skip」の not_if は撤廃した (旧設計だと volume mount 追加が
  # 既存ユーザに反映されず、今回の TLS バグと同じ落とし穴になる)。
  execute 'docker compose up tyaba proxy' do
    command "docker compose -f #{proxy_dir}/docker-compose.yaml up -d"
  end
else
  raise NotImplementedError
end
