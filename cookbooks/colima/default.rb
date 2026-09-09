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
  # cpu / memory / disk は colima stop 後の colima start で既存 VM へ反映できる。
  # ただし disk は拡張のみ可能で縮小はできない。
  # 固定設定 (arch / vmType / runtime / mountType / network) は後から変更できないため、
  # テンプレート差分がある場合は自動変更せず利用者に反映方法の判断を委ねる。
  # brew services 管理下では launchd が再起動するため、in-place 拡張後は VM を停止してから
  # サービスへ引き渡す。
  execute 'warn about existing Colima instance with stale template' do
    command <<~SH
      template='#{files_dir}/colima.yaml'
      cpu=$(awk '$1 == "cpu:" { print $2; exit }' "$template")
      memory=$(awk '$1 == "memory:" { print $2; exit }' "$template")
      disk=$(awk '$1 == "disk:" { print $2; exit }' "$template")

      echo "[dotfiles/colima] WARNING: Colima default instance already exists, so template changes will not be applied automatically." >&2
      echo "[dotfiles/colima] For cpu/memory/disk growth, update the existing VM in place: brew services stop colima && colima start --cpu ${cpu} --memory ${memory} --disk ${disk} && colima stop && brew services start colima" >&2
      echo "[dotfiles/colima] Delete and recreate only when changing fixed settings such as arch/vmType/runtime/mountType/network: brew services stop colima && colima delete && brew services start colima" >&2
    SH
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

  # brew services が started でも VM が止まっていることがあるため、状態を直接確認する。
  execute 'colima start (ensure VM is running)' do
    command 'brew services restart colima'
    not_if 'colima status >/dev/null 2>&1'
  end

  # 起動直後は docker.sock がまだ準備中のことがあるため、最大 60 秒だけ待つ。
  # タイムアウトしても docker 依存レシピ側の skip ガードへ進めるため失敗扱いにしない。
  execute 'wait for docker daemon via colima' do
    command <<~SH
      for _ in $(seq 1 30); do
        if docker info >/dev/null 2>&1; then
          exit 0
        fi
        sleep 2
      done

      echo "[dotfiles/colima] WARNING: Docker daemon did not become ready within 60 seconds after starting Colima; Docker-dependent later recipes will be skipped." >&2
      exit 0
    SH
  end
else
  # colima は macOS 専用。他 OS では何もしない (native docker daemon を使う)
end
