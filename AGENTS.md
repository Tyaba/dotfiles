# AGENTS.md

## Learned User Preferences

- エージェントが自動コミットしてはならない。コミットはユーザーが明示的に指示したときのみ行う
- ルールは発火条件中心に書き、詳細な手順はSKILL.mdに分離する。常時コンテキストを増やさない
- チェックリスト形式の発火条件はルール側に残す。発火漏れ防止のため
- coding.mdc の構成は「ツール活用 / 開発プロセス / 言語・FW固有」の大枠にまとめ、MCP一覧はフラットにする
- プラグインと自前ルール/スキルの重複は削る（例: Context7プラグイン導入後はcoding.mdcの1行説明を削除）
- Pythonの実行はuvを使う。テストはpytest。npm前提のスキルはPython環境では`uv run pytest`等で補う
- 重い指示やPR限定の指示はSkillに分離し、常時ルールに載せない
- pnpmは日常のパッケージ管理用、bunはランタイム/hook用として共存する
- Raycastのウィンドウ操作ホットキーはplistに出ないため手動設定が必要
- Spotlightの Cmd+Space はRaycastと競合するため無効化が必要
- `.cursor/hooks/state` はGit管理しない
- 認証情報・機密情報はコミットしない。リポジトリはpublicである

## Learned Workspace Facts

- プロビジョニングはMitamae + `./install.sh`。cookbooksでパッケージ管理する
- MCP設定は `config/.mcp.json.erb` のERBテンプレートからMitamaeで `~/.cursor/mcp.json` へ生成する
- MitamaeのtemplateでERB変数はインスタンス変数参照（`<%= @name %>`）を使う
- Cursor設定（skills・rules・MCP テンプレ）はdotfilesで管理する一貫した運用
- スキルは `config/.cursor/skills/` に配置し、`coding.mdc` に明示的な発火条件を書く
- Raycast設定の保存は `bin/raycast-export`、適用は `defaults import com.raycast.macos`
- キーボードはHHKB-Hybrid_2（Bluetooth接続）。CapsLock→left_controlはKarabiner simple_modificationsで変換
- Karabiner-Elementsのcomplex_modificationsでEmacs風キーバインドを全体適用（除外アプリリスト付き）
- yui MCPは会話履歴の圧縮版として位置づけ、参照・記録のハードルを低く運用する
- GCLOUD_PYTHON等の環境変数はフルパスで指定し、`-x`で実行可能か確認してからexportする
- PATH/補完は `.zshrc` 直書きせず `config/.zsh/lib/languages` に集約する
- PR作成時のAI監査セクションは「変更内容」の直後に配置する
