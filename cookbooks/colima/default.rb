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
  # brew services 管理下では launchd が再起動するため、再作成時は先にサービスを停止する。
  execute 'warn about existing Colima instance with stale template' do
    command 'echo "[dotfiles/colima] WARNING: Colima default instance already exists, so template changes will not be applied. Recreate it manually with: brew services stop colima && colima delete && brew services start colima" >&2'
    only_if "! cmp -s #{files_dir}/colima.yaml #{colima_config} && #{colima_default_exists}"
  end

  execute "install -m 0644 #{files_dir}/colima.yaml #{colima_config}" do
    not_if "cmp -s #{files_dir}/colima.yaml #{colima_config}"
  end

  colima_service_started = 'brew services list 2>/dev/null | awk \'$1 == "colima" && $2 == "started" { found = 1 } END { exit !found }\''

  # brew services 経由で launchd に登録することで、Mac 起動時の自動起動と install 時の起動を
  # どちらも Homebrew の service ブロック (colima start -f) に任せる。
  # ただし keep_alive successful_exit: true のため、手動起動中の VM が残ったまま登録すると、
  # 二重起動を検出した colima start -f が終了し、launchd が再起動を繰り返す可能性がある。
  # そのため、未登録の状態で既に起動しているインスタンスはサービスへ引き渡す前に停止する。
  execute 'colima stop (hand over to brew services)' do
    command 'colima stop'
    only_if "colima status >/dev/null 2>&1 && ! #{colima_service_started}"
  end

  # 登録後の VM 停止は brew services stop colima で行う。
  # colima stop だけでは launchd が colima start -f を再実行して VM を起動し直す。
  execute 'brew services start colima' do
    command 'brew services start colima'
    not_if colima_service_started
  end
else
  # colima は macOS 専用。他 OS では何もしない (native docker daemon を使う)
end
