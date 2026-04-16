# AGENTS.md

## Development Process

### ドキュメント更新
- 実装の変更を行った後は、ドキュメント（ワークスペース配下の README.md、.docs 配下）にも変更内容を反映せよ
- 処理フローは md 内の mermaid で表現せよ

---

## Learned User Preferences

- エージェントが自動コミットしてはならない。コミットはユーザーが明示的に指示したときのみ行う
- ルールは発火条件中心に書き、詳細な手順はSKILL.mdに分離する。常時コンテキストを増やさない。重い指示やPR限定の指示もSkillに分離する
- coding.mdcの構成は「ツール活用 / 開発プロセス / 言語・FW固有」の大枠にまとめ、プラグインと自前ルール/スキルの重複は削る
- Pythonの実行はuvを使う。テストはpytest。uvは公式インストーラー（curl）で導入
- pnpmは日常のパッケージ管理用、bunはランタイム/hook用として共存する
- Raycastのウィンドウ操作ホットキーはplistに出ないため手動設定が必要。Spotlight・Siri/Apple IntelligenceのCmd+Spaceは競合するため無効化（`darwin_base/default.rb`で自動化済み）
- `.cursor/hooks/state` はGit管理しない。認証情報・機密情報はコミットしない。リポジトリはpublicである
- ターミナルのカラーテーマはダーク×ウォーム系が好み（ネイビー系は嫌い）
- 個人の設定をプロジェクトの`.claude/rules/`に持ち込まない。グローバル設定（`~/.claude/CLAUDE.md`）で管理する
- Context7はCursor/Claude Code両方ともplugin版を使う（MCP serverとしては管理しない）
- 複数リポジトリの並列作業はtmuxセッション分離で行う（Ghosttyタブ複製ではなく）
- tmuxのprefixはCtrl+Space（デフォルトのCtrl+Bはカーソル移動と競合するため変更済み）
- Codexオフロードの移譲判断はrate limit依存ではなくタスク性質ベース。Claudeが特に優れる領域（設計・大規模リファクタ・MCP連携）以外は基本的にCodexに自動移譲する

## Learned Workspace Facts

- プロビジョニングはMitamae + `./install.sh`。cookbooksでパッケージ管理する
- MCP設定は `config/coding_agents/mcp.json.erb` のERBテンプレートからMitamaeで生成する。ERB変数はインスタンス変数参照（`<%= @name %>`）
- Cursor/Claude Code設定は `config/coding_agents/` に集約。共通ユーザ設定は `user-rules.md`、共通スキルは `skills/`、ツール固有は `cursor/`・`claude/` に分離
- CLAUDE.mdは`@~/.claude/user-rules.md`で共通ユーザ設定、`@AGENTS.md`でワークスペース固有設定をインポートする構成
- Cursorは`user-rules.mdc.erb`テンプレートから`~/.cursor/rules/user-rules.mdc`を生成し、全ワークスペースに共通ユーザ設定を適用
- Raycast設定の保存は `bin/raycast-export`、適用は `defaults import com.raycast.macos`。Spectacleは削除済み
- キーボードはHHKB-Hybrid_2（Bluetooth接続）。CapsLock→left_controlはKarabiner simple_modificationsで変換
- Karabiner-Elementsのcomplex_modificationsでEmacs風キーバインドを全体適用（除外アプリリスト付き）。`FromModifiers.optional`のデフォルトに`["caps_lock"]`が必要
- IME切り替え: Ctrl+\ → (Karabiner) → `japanese_eisuu`/`japanese_kana` → macOSネイティブ入力ソース切り替え。一方向キーのため二重発火なし、`select_input_source`のCJKVバグも回避。F18経由・`select_input_source`直接方式はいずれも非推奨
- CursorのbundleIDは`com.todesktop.230313mzl4w4u92`、Ghosttyは`com.mitchellh.ghostty`。いずれもKarabiner除外リストに含める
- Cursorでは`lfs.vscode-emacs-friendly`拡張でEmacsキーバインドを使用。`C-x C-c`はエディタ開→タブ閉じ、全閉じ→ウィンドウ閉じの2段階動作（`keybindings.json`で設定）。closeWindowの条件に`!multipleEditorGroups`を含めるとチャットパネル等で不成立になるため削除済み
- MCP serverのcommandや環境変数はフルパス指定が必要（例: `uvx`→`<%= ENV['HOME'] %>/.local/bin/uvx`）
- PATH/補完は `.zshrc` 直書きせず `config/.zsh/lib/languages` に集約する
- PR作成時のAI監査セクションは「変更内容」の直後に配置する
- Claude Codeのmodel設定は`opus[1m]`、permission modeは`auto`、サブエージェントも`opus`（通常コンテキスト）
- Claude Codeは`ANTHROPIC_API_KEY`が設定されているとOAuth/EnterpriseよりAPIキー認証が優先され、`/status`のLogin methodが「Claude API Account」になる。Enterpriseサブスク枠とstatusline入力の`rate_limits`（5時間・7日ウィンドウ）はOAuth（`/login`）で意味があり、APIキー主体では空になりやすい
- `terraform apply`はPreToolUse hookで動的ガード。plan結果にステートフルリソース（BQ/GCS/SQL/VM/Redis/Spanner/Bigtable/Filestore）のreplace/destroyがあればdeny、なければallow。`terraform destroy`は静的deny維持。hookスクリプトは`config/coding_agents/hooks/terraform-apply-guard.sh`
- Claude Codeの`gcloud`許可: 読み取り系(describe/list/get-iam-policy/config)と追加系(create/versions add/add-iam-policy-binding)はallow、deleteはdeny
- Claude Codeのstatusline.sh、output-styles/、render-diagram.shは`config/coding_agents/claude/`に配置し、`roles/base/default.rb`で`~/.claude/`にシンボリックリンク。プラグインは`/plugin`コマンドでインストールし`~/.claude.json`に永続（dotfilesで宣言的管理は不可）
- GhosttyでのURL開きはCmd+クリック、tmux内ではCmd+Shift+クリック（tmuxがマウスイベントを食うため）。`macos-option-as-alt = true`でAlt+矢印/Alt+B/F等のワード移動を有効化
- `config/.zsh/lib/functions` の `gcloud()` ラッパーはOS分岐でyui-proxy再起動を切り替え（macOS: launchctl, Linux: systemctl --user）
- ツール移行済み: exa→eza、ncdu→dust、pipx→廃止（uvは公式インストーラーに移行）、poetry→uv、iTerm→Ghostty、scroll-reverser→macOS標準。XQuartzはX11 forwarding用に必要（代替なし）
- mozc cookbookはrole未参照で残存（ユーザー未決定）
- Codex CLIは`codex mcp-server`でMCPサーバーとして動作し、`mcp.json.erb`で定義。`base-instructions`パラメータでClaude側のルールを動的注入可能。`~/.codex/AGENTS.md`は直接CLI利用時のグローバルルール。CI環境では利用不可（OAuth認証にブラウザフロー必須）。`config/coding_agents/codex/AGENTS.md`→`~/.codex/AGENTS.md`でデプロイ
