@~/.claude/user-rules.md
@AGENTS.md

# Claude Code 固有設定

## Codex オフロード

`user-rules.md` の「Codex オフロード」節と `codex-offload` skill に従い、**コード変更を伴うタスクはデフォルトで `mcp__codex__codex` に移譲する**。

Claude Code 固有の注意：

- `Edit` / `Write` / `NotebookEdit` を**初めて呼ぶ前に**着手前ゲートの自問を行う（ツール呼び出し開始後では遅い）
- Task サブエージェント（Explore 等）は**読み取り中心**、Codex は**書き込み系**で使い分け

## サブエージェント
- **大規模な読み取り中心の探索**: Task ツール（Explore エージェント）
- **異なるブランチで並列作業**: 必ず `isolation: "worktree"` を指定（同一 CWD での並列 `git checkout` は競合）

## TDD
実装追加時は `/red` → `/green` → `/refactor` を順に実行し、各フェーズ完了時にコミット。各フェーズの実装自体は Codex 移譲可、サイクル進行は Claude が担う。
