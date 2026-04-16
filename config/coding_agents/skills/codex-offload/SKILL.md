---
name: codex-offload
description: codex-plugin-cc を使った効果的なプロンプト構成ガイド。移譲判断基準は user-rules.md に常時記載
---

# Codex Offload — プロンプト構成ガイド

Codex にタスクを渡す際のプロンプト構成と、コマンドの使い分けを定義する。
移譲判断基準は `user-rules.md` の「Codex オフロード」セクションを参照。

## コマンド使い分け

### `/codex:review` -- コードレビュー

uncommitted changes または特定ブランチのレビュー。read-only。

```
/codex:review                    # 現在の変更をレビュー
/codex:review --base main        # main との差分をレビュー
/codex:review --background       # バックグラウンド実行
```

### `/codex:adversarial-review` -- 設計批判レビュー

実装の方向性・トレードオフ・リスクを問う。review より深い。

```
/codex:adversarial-review --base main
/codex:adversarial-review --background challenge the caching strategy
```

### `/codex:rescue` -- タスク委譲

実際の作業を Codex に渡す。write モードがデフォルト。

```
/codex:rescue investigate why the tests are failing
/codex:rescue fix the lint errors in src/
/codex:rescue --background implement the validation logic
```

## プロンプト構成ガイド

Codex にタスクを渡す際は、以下の原則に従う。codex-plugin-cc 付属の `gpt-5-4-prompting` スキルに準拠。

### 基本原則

- **1 タスク 1 Codex 実行**: 無関係なタスクは別々の実行に分ける
- **完了条件を明示する**: Codex が推測しなくて済むように「done」の状態を定義する
- **XML タグで構造化**: `<task>`, `<structured_output_contract>`, `<verification_loop>` 等を使う

### コンテキスト補完

Codex は `~/.codex/AGENTS.md` のグローバルルールを読むが、Claude 固有のルール（`CLAUDE.md`, `user-rules.md`）や MCP の情報は持たない。
プロジェクト固有の重要なコンテキストがある場合は、プロンプトに明示的に含める。

例:
```
/codex:rescue fix the failing test. Note: this project uses DDD layer architecture — domain layer must not depend on infrastructure layer.
```

### タスク別テンプレート

**バグ修正:**
```
/codex:rescue diagnose and fix the failing test in tests/test_foo.py. Apply the smallest safe patch without unrelated refactors.
```

**コードレビュー後の修正:**
```
/codex:rescue address the review feedback: [具体的なフィードバック内容]. Keep changes scoped to the feedback only.
```

**テスト追加:**
```
/codex:rescue add unit tests for src/services/bar.py. Cover edge cases and error paths. Use pytest.
```

## 注意事項

- **review gate は慎重に**: `/codex:setup --enable-review-gate` は Claude/Codex のループを引き起こし、usage を急速に消費する。常時監視できる場合のみ有効化する
- **バックグラウンド推奨**: マルチファイルの変更を伴うタスクは `--background` で実行し、`/codex:status` と `/codex:result` で確認する
- **resume で継続**: 前回の Codex タスクを継続する場合は `/codex:rescue --resume` を使う
