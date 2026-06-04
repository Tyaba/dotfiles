---
name: codex-offload
description: Claude から Codex (`mcp__codex__codex`) へコード変更系タスクを移譲する際の呼び出し手順・必須引数・承認プロンプト抑止の根拠をまとめたスキル。
---

# Codex オフロード

コード変更を伴うタスクはデフォルトで Codex に移譲する。Claude が自ら実装するのは
`user-rules.md` の「Claude に残すタスク」に該当する場合のみ。

## 着手前ゲート

`Edit` / `Write` / `NotebookEdit` / コード生成系 `Bash` を**初めて呼ぶ前**に順に自問：

0. **前段の手続き型ルールが未実行ではないか？** TDD・`pr-template`・`ddd-scaffold`・`terraform-migration` 等の前段手続きが定義されている場合、それを先に開始する。移譲ゲートは前段ルールに優先しない
1. このタスクは「Claude に残すタスク」に該当するか？
2. 該当しなければ、コードを書き始めず `mcp__codex__codex` に移譲する。

「小さい修正だから」「すぐ終わるから」は移譲を省略する理由にならない（Codex 側でも同じく小さく済む）。

## 移譲の粒度（一括移譲の禁止）

移譲は原則として**ワークフローの 1 フェーズ単位**で行う。複数フェーズを 1 回の呼び出しに詰め込まない。
理由: フェーズ間で Claude が行う検証・コミット・テンプレ準拠確認が吹き飛び、手続き型ルールが実質無効化されるため。

禁止例と正しい例：

- ❌ 「機能 X を実装して、テストも書いて」と 1 回で Codex に投げる（TDD サイクルを破壊）
- ✅ `/red` で失敗テスト作成を Codex に依頼 → Claude が失敗確認＋コミット → `/green` で最小実装を Codex → Claude が通過確認＋コミット → `/refactor`
- ❌ 「変更内容を踏まえて PR を作って」と 1 回で Codex に投げる（PR template が無視される）
- ✅ Claude が `pr-template` スキルを読み、`git diff` / `git log` を把握し、テンプレに沿って description を組み立てる。コード生成以外の文章組み立ては Claude の仕事

## 呼び出しテンプレート

```
mcp__codex__codex(
  prompt="<具体的なタスク指示。対象ファイル・期待する結果・制約を明示>",
  base-instructions="<プロジェクト固有のコンテキスト。DDD構造、命名規約、言語/FWルール等>",
  cwd="<作業対象プロジェクトの絶対パス>",
  approval-policy="never",
  sandbox="workspace-write"
)
```

- `base-instructions`: `AGENTS.md` / `CLAUDE.md` の抜粋や関連ファイルパスを渡す。Codex は Claude のルールを自動では読まない
- 移譲後は Codex の出力を検証してユーザーに報告する。Codex の回答を鵜呑みにして転記するのは禁止

## 必須引数（承認プロンプト抑止のため毎回明示）

`cwd` / `approval-policy` / `sandbox` の 3 つは毎回引数で渡す。理由：

- `codex mcp-server` は起動時の `-c approval_policy=never` や `~/.codex/config.toml` の設定を MCP 経路の承認判定に正しく伝播できないバグがある（openai/codex#17238, #18268, #11816）。設定だけでは親ホスト（Claude Code 等）に escalation プロンプトが surface してしまう
- 同サーバーは **MCP tool call の引数を起動時 config より優先**する設計のため、引数で上書きすれば確実に効く
- `cwd` は tool 側の sandbox workspace の基点。対象リポジトリのルート絶対パスを渡す（相対パスは MCP サーバーの CWD 基準になり混乱を招く）

### worktree-per-session での cwd 規律とブランチガード

tyaba-env の `mise run claude` は 1 container/repo で session ごとに `.worktrees/<slug>`（branch `claude/<slug>`）を作り、その中で Claude を起動する。**同じ container にメインの checkout（`/workspaces/<repo>`, branch=main/epic）が同居する**ため、cwd の取り違えが「気づかないうちに別ブランチへ書き込む」事故に直結する。devcontainer デフォルトの `danger-full-access` では sandbox が cwd を強制しないので、この規律は運用で担保する。

- **offload 時に `cwd` を worktree の絶対パス（Claude 自身の作業ディレクトリ）で必ず明示する。** Codex は Claude の cwd を継承しない独立プロセスなので、暗黙の継承に頼らない
- worktree では commit 先ブランチは cwd → worktree HEAD から自動解決されるためブランチ名の指定は不要。ただし **cwd がリポジトリルートに滑ると静かに main/epic へ commit される**
- Codex の git 操作・Claude の commit は **worktree 内で行う**。`git -C <repo-root>` やルートへの `cd` は避ける
- **commit 直前にブランチをガードする**: `git rev-parse --abbrev-ref HEAD` が `claude/<slug>` であることを確認してから add/commit する。想定外なら commit せず原因を調べる

### デフォルト値

- `approval-policy="never"`
- `sandbox`:
  - devcontainer 内 (`$DOTFILES_ROLE=devcontainer`): `"danger-full-access"` をデフォルトに昇格。blast radius は container 内で閉じるので、`/tmp` や `~/.cache` への書き込みも含めて確認不要で許可する
  - host 直 (それ以外): `"workspace-write"`。workspace 外パスを触る必要があるときのみ `"danger-full-access"` への昇格を検討し、その旨をユーザに確認する

### 破壊的操作前の注意（devcontainer）

devcontainer は workspace を bind mount しているため、`rm -rf` / `git reset --hard` / `git clean -f` 等の破壊的操作は **host 側の未コミット作業も巻き込む**。Codex に破壊的操作を含むタスクを移譲する前に、関連ファイルを commit するかブランチを保存しておくこと。

### writable_roots

`~/.codex/config.toml`（dotfiles: `config/coding_agents/codex/config.toml.erb`）で `$HOME/ghq` を通してあるので、ghq 配下のリポジトリ間で参照・書き込みが必要なコマンドは追加設定なしで通る想定。

## stuck 検知

同じ仮説で 2–3 回試して失敗したら、追加試行せず Codex に移譲する。
