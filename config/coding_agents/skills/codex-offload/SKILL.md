---
name: codex-offload
description: Claude から Codex CLI へコード変更系タスクを移譲する際の呼び出し手順・移譲の粒度・sandbox 設定の根拠をまとめたスキル。移譲は `codex-offload` サブエージェント経由で行う。
---

# Codex オフロード

コード変更を伴うタスクはデフォルトで Codex に移譲する。Claude が自ら実装するのは
`user-rules.md` の「Claude に残すタスク」に該当する場合のみ。

## 着手前ゲート

`Edit` / `Write` / `NotebookEdit` / コード生成系 `Bash` を**初めて呼ぶ前**に順に自問：

0. **前段の手続き型ルールが未実行ではないか？** TDD・`pr-template`・`ddd-scaffold`・`terraform-migration` 等の前段手続きが定義されている場合、それを先に開始する。移譲ゲートは前段ルールに優先しない
1. このタスクは「Claude に残すタスク」に該当するか？
2. 該当しなければ、コードを書き始めず `codex-offload` サブエージェントに移譲する。

「小さい修正だから」「すぐ終わるから」は移譲を省略する理由にならない（Codex 側でも同じく小さく済む）。

## 移譲の粒度（一括移譲の禁止）

移譲は原則として**ワークフローの 1 フェーズ単位**で行う。複数フェーズを 1 回の呼び出しに詰め込まない。
理由: フェーズ間で Claude が行う検証・コミット・テンプレ準拠確認が吹き飛び、手続き型ルールが実質無効化されるため。

禁止例と正しい例：

- ❌ 「機能 X を実装して、テストも書いて」と 1 回で Codex に投げる（TDD サイクルを破壊）
- ✅ `/red` で失敗テスト作成を Codex に依頼 → Claude が失敗確認＋コミット → `/green` で最小実装を Codex → Claude が通過確認＋コミット → `/refactor`
- ❌ 「変更内容を踏まえて PR を作って」と 1 回で Codex に投げる（PR template が無視される）
- ✅ Claude が `pr-template` スキルを読み、`git diff` / `git log` を把握し、テンプレに沿って description を組み立てる。コード生成以外の文章組み立ては Claude の仕事

## 呼び出し方

Task ツールで `codex-offload` サブエージェント（`~/.claude/agents/codex-offload.md`、dotfiles の実体は
`config/coding_agents/claude/agents/codex-offload.md`）を起動する。サブエージェントが内部で
`codex exec --json -o <file> "<プロンプト>"` を実行し、`git diff` で実際の差分を確認してから結果を返す。

サブエージェントに渡す指示に必ず含めるもの：

- **作業ディレクトリの絶対パス**。codex は cwd を sandbox と git 解決の基点にする。worktree 運用では特に重要（後述）
- 具体的なタスク指示（対象ファイル・期待する結果・制約）
- プロジェクト固有のコンテキスト（DDD 構造、命名規約、言語 / FW ルール等）。`AGENTS.md` / `CLAUDE.md` の該当箇所を抜粋して渡す。Codex は Claude のルールも MCP 接続も継承しない独立プロセスなので、暗黙の共有を期待しない

移譲後は Codex の出力を検証してユーザーに報告する。Codex の回答を鵜呑みにして転記するのは禁止。

追加指示で同じスレッドを続ける場合は `codex exec resume --last "<追加指示>"`。新しいスレッドを立てると、
直前の変更内容を Codex が把握していない状態からやり直しになる。

## sandbox と承認ポリシーを引数で渡さない

`sandbox_mode` / `approval_policy` は `$CODEX_HOME/config.toml`（dotfiles:
`config/coding_agents/codex/config.toml.erb`）に環境ごとの正しい値が入っており、`codex exec` はそれを読む。
`-c sandbox_mode=...` や `--dangerously-bypass-approvals-and-sandbox` をコマンドラインに足さない。
足すと host 側の隔離が黙って外れる。

かつて MCP 経由（`codex mcp-server`）では引数で毎回上書きする必要があった。起動時の `-c` や config.toml が
承認判定に伝播しないバグ（openai/codex#17238, #18268, #11816）があったため。`codex exec` にはこの問題はなく、
`mcp-server` 自体が codex 0.154.0 で削除された。

### worktree-per-session での cwd 規律とブランチガード

tyaba-env の `mise run claude` は 1 container/repo で session ごとに `.worktrees/<slug>`（branch `claude/<slug>`）を作り、その中で Claude を起動する。**同じ container にメインの checkout（`/workspaces/<repo>`, branch=main/epic）が同居する**ため、cwd の取り違えが「気づかないうちに別ブランチへ書き込む」事故に直結する。devcontainer デフォルトの `danger-full-access` では sandbox が cwd を強制しないので、この規律は運用で担保する。

- **offload 時に `cwd` を worktree の絶対パス（Claude 自身の作業ディレクトリ）で必ず明示する。** Codex は Claude の cwd を継承しない独立プロセスなので、暗黙の継承に頼らない
- worktree では commit 先ブランチは cwd → worktree HEAD から自動解決されるためブランチ名の指定は不要。ただし **cwd がリポジトリルートに滑ると静かに main/epic へ commit される**
- Codex の git 操作・Claude の commit は **worktree 内で行う**。`git -C <repo-root>` やルートへの `cd` は避ける
- **commit 直前にブランチをガードする**: `git rev-parse --abbrev-ref HEAD` が `claude/<slug>` であることを確認してから add/commit する。想定外なら commit せず原因を調べる

### 環境ごとの値（config.toml 側で設定済み）

- host: `sandbox_mode = "workspace-write"` + `writable_roots = ["$HOME/ghq"]` + `network_access = true`。
  workspace 外のパスを触る必要があるときだけ昇格を検討し、その旨をユーザに確認する
- devcontainer: `sandbox_mode = "danger-full-access"`。blast radius が container 内で閉じるので、`/tmp` や
  `~/.cache` への書き込みも確認不要で許可する。ubuntu ベースの container は非特権 user namespace が無効なため、
  `workspace-write` で呼ぶと Codex 内のシェル実行が `bwrap: No permissions to create a new namespace` で全滅し、
  `approval_policy = "never"` のため昇格も拒否されて「何も編集していないのに完了報告が返る」状態になる
- 両環境とも `approval_policy = "never"`

この user namespace の制約が、公式プラグイン `codex@openai-codex` を devcontainer で使えない理由でもある。
プラグインは sandbox を `workspace-write` / `read-only` にハードコードしており config.toml を読まない
（openai/codex-plugin-cc#482, #505）。そのためプラグインは host のみに入れてある。

### 破壊的操作前の注意（devcontainer）

devcontainer は workspace を bind mount しているため、`rm -rf` / `git reset --hard` / `git clean -f` 等の破壊的操作は **host 側の未コミット作業も巻き込む**。Codex に破壊的操作を含むタスクを移譲する前に、関連ファイルを commit するかブランチを保存しておくこと。

### writable_roots

`$CODEX_HOME/config.toml`（dotfiles: `config/coding_agents/codex/config.toml.erb`）で `$HOME/ghq` を通してあるので、ghq 配下のリポジトリ間で参照・書き込みが必要なコマンドは追加設定なしで通る想定。

`$CODEX_HOME` は host では `~/.codex`、devcontainer では `~/.config/codex`。devcontainer では `~/.codex` が host と rw bind mount で共有されており、`$HOME` 絶対パスと `sandbox_mode` が両立しないため分離してある（`auth.json` のみ symlink で共有）。なお devcontainer は `danger-full-access` なので `writable_roots` は bypass される。

## stuck 検知

同じ仮説で 2–3 回試して失敗したら、追加試行せず Codex に移譲する。
