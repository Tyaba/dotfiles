---
name: codex-offload
description: Codex MCP サーバー経由でのタスク移譲のプロンプト構成ガイド。移譲判断基準は user-rules.md に常時記載
---

# Codex Offload — プロンプト構成ガイド

Codex MCP サーバー (`mcp__codex__codex`) を使ったタスク移譲のプロンプト構成を定義する。
移譲判断基準は `user-rules.md` の「Codex オフロード」セクションを参照。

## MCP ツール

### `mcp__codex__codex` -- タスク実行

Codex セッションを開始する。主要パラメータ:

| パラメータ | 型 | 説明 |
|---|---|---|
| `prompt` (必須) | string | タスク指示 |
| `base-instructions` | string | デフォルトの指示を上書きするカスタム指示 |
| `approval-policy` | string | `untrusted`, `on-request`, `never` |
| `sandbox` | string | `read-only`, `workspace-write`, `danger-full-access` |
| `model` | string | モデル指定（例: `o3`, `o4-mini`） |
| `cwd` | string | 作業ディレクトリ |

### `mcp__codex__codex-reply` -- セッション継続

既存の Codex セッションを継続する。`threadId` で前回のセッションを指定。

## プロンプト構成ガイド

### 基本原則

- **1 タスク 1 Codex 実行**: 無関係なタスクは別々の実行に分ける
- **完了条件を明示する**: Codex が推測しなくて済むように「done」の状態を定義する
- **`base-instructions` を活用する**: プロジェクト固有のルール（DDD構造、命名規約、テスト方針等）を渡す

### `base-instructions` によるコンテキスト注入

Codex は `~/.codex/AGENTS.md` のグローバルルールを読むが、Claude 固有のルール（`CLAUDE.md`, `user-rules.md`）は持たない。
`base-instructions` パラメータでプロジェクト固有のコンテキストを動的に注入できる。

呼び出し例:
```json
{
  "prompt": "Fix the failing test in tests/test_auth.py",
  "base-instructions": "This project uses DDD layer architecture. Domain layer must not depend on infrastructure. Use pytest for tests.",
  "approval-policy": "never",
  "sandbox": "workspace-write"
}
```

### タスク別テンプレート

**バグ修正:**
```json
{
  "prompt": "Diagnose and fix the failing test in tests/test_foo.py. Apply the smallest safe patch without unrelated refactors.",
  "approval-policy": "never",
  "sandbox": "workspace-write"
}
```

**テスト追加:**
```json
{
  "prompt": "Add unit tests for src/services/bar.py. Cover edge cases and error paths. Use pytest.",
  "approval-policy": "never",
  "sandbox": "workspace-write"
}
```

**コードレビュー:**
```json
{
  "prompt": "Review the uncommitted changes for correctness, security, and performance issues. Report findings ordered by severity.",
  "sandbox": "read-only"
}
```

**lint 修正:**
```json
{
  "prompt": "Fix all ruff lint errors in src/. Do not change logic.",
  "approval-policy": "never",
  "sandbox": "workspace-write"
}
```

## 注意事項

- **`approval-policy`**: write 系タスクは `never` で自動承認。レビュー・調査は `read-only` sandbox が安全
- **`codex-reply` でセッション継続**: 前回の結果を踏まえて追加指示を出す場合は `threadId` を使って `codex-reply` で継続する
- **stuck 検知**: Claude が同じ仮説を 2-3 回試して失敗した場合、Codex に移譲して fresh perspective を得る
