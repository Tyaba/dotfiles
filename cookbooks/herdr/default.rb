# herdr — agent-aware terminal multiplexer (https://herdr.dev)
#
# tmux の置き換え。Workspace > Tab > Pane が tmux の Session > Window > Pane に
# 対応し、prefix も設定で Ctrl+Space に合わせてある (config/.config/herdr/config.toml)。
# tmux との最大の差は、pane の前景プロセスからコーディングエージェントを識別し、
# 画面出力から idle / working / blocked / done を判定する点。
case node[:platform]
when 'darwin'
  # Homebrew formula (brew install herdr) が公式に提供されている
  herdr_bin = '/opt/homebrew/bin/herdr'
  execute 'brew install herdr' do
    not_if "test -x #{herdr_bin}"
  end
when 'ubuntu', 'debian'
  # Linux は公式インストールスクリプト経由。単一の静的バイナリを
  # $HOME/.local/bin へ置くだけで、cookbooks/claude と同じ配置先になる。
  herdr_bin = "#{ENV['HOME']}/.local/bin/herdr"
  execute 'install herdr' do
    command 'curl -fsSL https://herdr.dev/install.sh | sh'
    not_if "test -x #{herdr_bin}"
  end
else
  raise NotImplementedError
end

# herdr は ~/.config/herdr に herdr.sock を作るため、ディレクトリごとではなく
# config.toml だけを symlink する (socket がリポジトリ作業ツリーに落ちるのを避ける)
dotfile '.config/herdr/config.toml'

# エージェント状態通知の hook。
#
# `herdr integration install claude` が 2 つのことをする:
#   1. ~/.claude/hooks/herdr-agent-state.sh を生成する
#   2. ~/.claude/settings.json に SessionStart hook として登録する
#
# 生成物をコミットしない理由:
#   - スクリプトは herdr のバージョンごとに生成される (`integration status` が
#     `claude: current (v8)` のように版を報告する)。アップグレード時に再生成が必要
#   - roles/base が ~/.claude/hooks を config/coding_agents/hooks への symlink に
#     するため、生成物はこのリポジトリの作業ツリー内に落ちる。.gitignore 済み
#
# roles/base は settings.json.erb から ~/.claude/settings.json を毎回描画し直すので
# 1 の登録が消える。この cookbook を `include_role 'base'` より後に include して
# あるため、install.sh の 1 回の実行内で再登録され収束する。
execute 'install herdr claude integration' do
  command "#{herdr_bin} integration install claude"
  not_if "#{herdr_bin} integration status | grep -q '^claude: current'"
end

# herdr はキーバインドを常駐 server が保持しており、TUI クライアントを
# 開き直しても config.toml は再読込されない。symlink を張り替えただけでは
# 設定変更が反映されないため、install.sh の中で明示的に reload させる。
#
# CI・初回セットアップ・devcontainer など server が起動していない環境でも
# install.sh 全体を落とさないため、reload 失敗時は成功扱いにする。
execute 'reload herdr config' do
  command "#{herdr_bin} server reload-config || true"
end
