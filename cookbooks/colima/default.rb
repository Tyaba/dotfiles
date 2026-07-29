# Colima cookbook - lightweight Docker daemon alternative for macOS.
# Uses Lima VM under the hood, providing a Docker Desktop-compatible socket
# at ~/.colima/default/docker.sock. See cookbooks/docker/default.rb for the
# brew formula-based docker CLI stack (docker / docker-compose / docker-buildx)
# which colima requires.

files_dir = File.join(File.dirname(__FILE__), 'files')
colima_config_dir = "#{ENV['HOME']}/.colima/default"
colima_config = "#{colima_config_dir}/colima.yaml"

case node[:platform]
when 'darwin'
  execute 'brew install colima' do
    command 'brew install colima'
    not_if 'which colima'
  end

  execute "mkdir -p #{colima_config_dir}" do
    not_if "test -d #{colima_config_dir}"
  end

  execute "install -m 0644 #{files_dir}/colima.yaml #{colima_config}" do
    not_if "cmp -s #{files_dir}/colima.yaml #{colima_config}"
  end

  # colima start は初回だけ実行 (以降は login item / 手動で管理)。
  # 既に走っていれば no-op。設定変更の反映は `colima restart` を手動で。
  execute 'colima start (initial)' do
    command 'colima start'
    not_if 'colima status >/dev/null 2>&1'
  end
else
  # colima は macOS 専用。他 OS では何もしない (native docker daemon を使う)
end
