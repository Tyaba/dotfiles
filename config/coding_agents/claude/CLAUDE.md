@~/.claude/user-rules.md
@AGENTS.md

# Claude Code 固有設定

## Codex オフロード

`user-rules.md` の「Codex オフロード」節と `codex-offload` skill に従い、**コード変更を伴うタスクはデフォルトで `codex-offload` サブエージェントに移譲する**。

Claude Code 固有の注意：

- `Edit` / `Write` / `NotebookEdit` を**初めて呼ぶ前に**着手前ゲートの自問を行う（ツール呼び出し開始後では遅い）
- `codex-offload` は Task ツールで起動するサブエージェント（`~/.claude/agents/codex-offload.md`）。内部で `codex exec` を実行する。以前の `mcp__codex__codex` は codex 0.154.0 の `mcp-server` 削除で消滅した
- ホストでは公式プラグイン `codex@openai-codex` も入っており、人間が明示的に使うレビュー系コマンド（`/codex:review` 等）と `codex-rescue` サブエージェントが利用できる。devcontainer では sandbox の都合で無効（`codex-offload` を使う）
- 読み取り中心の探索は Explore サブエージェント、書き込み系は Codex、と使い分ける

## サブエージェント
- **大規模な読み取り中心の探索**: Task ツール（Explore エージェント）
- **異なるブランチで並列作業**: 必ず `isolation: "worktree"` を指定（同一 CWD での並列 `git checkout` は競合）

## TDD
実装追加時は `/red` → `/green` → `/refactor` を順に実行し、各フェーズ完了時にコミット。各フェーズの実装自体は Codex 移譲可、サイクル進行は Claude が担う。

<tone_preference>
応答は簡潔に。結論は末尾に短く置き、そこだけ読んで分かるように書く（「案 B」「その関数」のようなラベル参照をせず毎回中身を書く）。
</tone_preference>
