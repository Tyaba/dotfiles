---
name: codex-offload
description: Claude から Codex (`mcp__codex__codex`) へコード変更系タスクを移譲する際の呼び出し手順・必須引数・承認プロンプト抑止の根拠をまとめたスキル。
---

# Codex オフロード

コード変更を伴うタスクはデフォルトで Codex に移譲する。Claude が自ら実装するのは
`user-rules.md` の「Claude に残すタスク」に該当する場合のみ。

## 着手前ゲート

`Edit` / `Write` / `NotebookEdit` / コード生成系 `Bash` を**初めて呼ぶ前**に自問：

1. このタスクは「Claude に残すタスク」に該当するか？
2. 該当しなければ、コードを書き始めず `mcp__codex__codex` に移譲する。

「小さい修正だから」「すぐ終わるから」は移譲を省略する理由にならない（Codex 側でも同じく小さく済む）。

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

### デフォルト値

- `approval-policy="never"`
- `sandbox="workspace-write"`

workspace 外パスを触る必要があるときのみ `sandbox="danger-full-access"` への昇格を検討し、その旨をユーザに確認する。

### writable_roots

`~/.codex/config.toml`（dotfiles: `config/coding_agents/codex/config.toml.erb`）で `$HOME/ghq` を通してあるので、ghq 配下のリポジトリ間で参照・書き込みが必要なコマンドは追加設定なしで通る想定。

## stuck 検知

同じ仮説で 2–3 回試して失敗したら、追加試行せず Codex に移譲する。
