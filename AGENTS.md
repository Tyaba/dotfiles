# AGENTS.md

## Development Process

### ドキュメント更新
- 実装の変更を行った後は、ドキュメント（ワークスペース配下の README.md、.docs 配下）にも変更内容を反映せよ
- 処理フローは md 内の mermaid で表現せよ

---

## Learned User Preferences

- エージェントが自動コミットしてはならない。コミットはユーザーが明示的に指示したときのみ行う
- ルールは発火条件中心に書き、詳細な手順はSKILL.mdに分離する。常時コンテキストを増やさない。チェックリスト形式の発火条件はルール側に残す
- coding.mdc の構成は「ツール活用 / 開発プロセス / 言語・FW固有」の大枠にまとめ、MCP一覧はフラットにする
- プラグインと自前ルール/スキルの重複は削る（例: Context7プラグイン導入後はcoding.mdcの1行説明を削除）
- Pythonの実行はuvを使う。テストはpytest。npm前提のスキルはPython環境では`uv run pytest`等で補う
- 重い指示やPR限定の指示はSkillに分離し、常時ルールに載せない
- pnpmは日常のパッケージ管理用、bunはランタイム/hook用として共存する
- Raycastのウィンドウ操作ホットキーはplistに出ないため手動設定が必要
- Spotlight・Siri/Apple IntelligenceのCmd+SpaceはRaycastと競合するため無効化が必要（`darwin_base/default.rb`で自動化済み）
- `.cursor/hooks/state` はGit管理しない。認証情報・機密情報はコミットしない。リポジトリはpublicである
- ターミナルのカラーテーマはダーク×ウォーム系が好み（ネイビー系は嫌い）
- 個人の設定をプロジェクトの`.claude/rules/`に持ち込まない。グローバル設定（`~/.claude/CLAUDE.md`）で管理する
- Context7はCursor/Claude Code両方ともplugin版を使う（MCP serverとしては管理しない）
- Obsidian MCPはもう使っていない。関連する残骸（pull-vault.sh等）は削除対象
- 複数リポジトリの並列作業はtmuxセッション分離で行う（Ghosttyタブ複製ではなく）
- tmuxのprefixはCtrl+Space（デフォルトのCtrl+Bはカーソル移動と競合するため変更済み）

## Learned Workspace Facts

- プロビジョニングはMitamae + `./install.sh`。cookbooksでパッケージ管理する
- MCP設定は `config/coding_agents/mcp.json.erb` のERBテンプレートからMitamaeで生成する。ERB変数はインスタンス変数参照（`<%= @name %>`）
- Cursor/Claude Code設定は `config/coding_agents/` に集約。共通ユーザ設定は `user-rules.md`、共通スキルは `skills/`、ツール固有は `cursor/`・`claude/` に分離
- CLAUDE.mdは`@~/.claude/user-rules.md`で共通ユーザ設定、`@AGENTS.md`でワークスペース固有設定をインポートする構成
- Cursorは`user-rules.mdc.erb`テンプレートから`~/.cursor/rules/user-rules.mdc`を生成し、全ワークスペースに共通ユーザ設定を適用
- Raycast設定の保存は `bin/raycast-export`、適用は `defaults import com.raycast.macos`。Spectacleは削除済み
- キーボードはHHKB-Hybrid_2（Bluetooth接続）。CapsLock→left_controlはKarabiner simple_modificationsで変換
- Karabiner-Elementsのcomplex_modificationsでEmacs風キーバインドを全体適用（除外アプリリスト付き）。`FromModifiers.optional`のデフォルトに`["caps_lock"]`が必要
- CursorのbundleIDは`com.todesktop.230313mzl4w4u92`、Ghosttyは`com.mitchellh.ghostty`。いずれもKarabiner除外リストに含める
- MCP serverのcommandや環境変数はフルパス指定が必要（例: `uvx`→`<%= ENV['HOME'] %>/.local/bin/uvx`）
- yui MCPは会話履歴の圧縮版として位置づけ、参照・記録のハードルを低く運用する
- PATH/補完は `.zshrc` 直書きせず `config/.zsh/lib/languages` に集約する
- PR作成時のAI監査セクションは「変更内容」の直後に配置する
- Claude Codeのmodel設定は`opus[1m]`、permission modeは`auto`、サブエージェントも`opus`（通常コンテキスト）
- Claude Codeのstatusline.sh、output-styles/、render-diagram.shは`config/coding_agents/claude/`に配置し、`roles/base/default.rb`で`~/.claude/`にシンボリックリンク
- Claude Codeのプラグインは`/plugin`コマンドでインタラクティブにインストールし`~/.claude.json`に永続する（dotfilesで宣言的管理は不可）
- GhosttyでのURL開きはCmd+クリック、tmux内ではCmd+Shift+クリック（tmuxがマウスイベントを食うため）
