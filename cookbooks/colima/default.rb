# Colima cookbook - lightweight Docker daemon alternative for macOS.
# Uses Lima VM under the hood, providing a Docker Desktop-compatible socket
# at ~/.colima/default/docker.sock. See cookbooks/docker/default.rb for the
# brew formula-based docker CLI stack (docker / docker-compose / docker-buildx)
# which colima requires.

files_dir = File.join(File.dirname(__FILE__), 'files')
colima_config_dir = "#{ENV['HOME']}/.colima/_templates"
colima_config = "#{colima_config_dir}/default.yaml"

case node[:platform]
when 'darwin'
  execute 'brew install colima' do
    command 'brew install colima'
    not_if 'which colima'
  end

  execute "mkdir -p #{colima_config_dir}" do
    not_if "test -d #{colima_config_dir}"
  end

  colima_default_exists = 'colima list 2>/dev/null | awk \'NR > 1 && $1 == "default" {found=1} END {exit !found}\''

  # Colima は新規インスタンス作成時だけ ~/.colima/_templates/default.yaml を読む。
  # ~/.colima/default/colima.yaml は colima start が書き出す生成物であり、
  # 既存 VM の固定設定 (arch / vmType / runtime / mountType / network) は後から変更できないため、
  # テンプレート差分がある場合は自動 delete せず利用者に再作成判断を委ねる。
  execute 'warn about existing Colima instance with stale template' do
    command 'echo "[dotfiles/colima] WARNING: Colima default instance already exists, so template changes will not be applied. Recreate it manually with: colima delete && colima start" >&2'
    only_if "! cmp -s #{files_dir}/colima.yaml #{colima_config} && #{colima_default_exists}"
  end

  execute "install -m 0644 #{files_dir}/colima.yaml #{colima_config}" do
    not_if "cmp -s #{files_dir}/colima.yaml #{colima_config}"
  end

  # colima start は初回だけ実行 (以降は login item / 手動で管理)。
  # 停止中の既存インスタンスにも古い固定設定が残るため、存在する場合は自動起動しない。
  execute 'colima start (initial)' do
    command 'colima start'
    not_if colima_default_exists
  end
else
  # colima は macOS 専用。他 OS では何もしない (native docker daemon を使う)
end
