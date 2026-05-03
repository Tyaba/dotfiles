---
name: mcp-yui
description: yui は会話履歴の圧縮版。エンティティ・ファクト・エピソード・サマリの 4 層からなる Hybrid Memory として永続化し、会話を跨いで長期記憶を提供する。
---

# yui MCP — Hybrid Memory Architecture

yui は対話を圧縮し、ナレッジグラフとして永続化する。
会話が終われば LLM は全てを忘れるが、yui に保存された知識は次の会話で復元される。

## データモデル

| コレクション | 役割 | 例 |
|---|---|---|
| **entities** | ノード = 人物・組織・ツール・概念・場所・プロジェクト | `吉野哲平` (person) / `yui` (project) |
| **facts** | エッジ = エンティティ間の関係 + メタデータ | `吉野哲平 ─develops→ yui` (category=work, confidence=0.9) |
| **episodes** | エピソード記憶 = セッションのナラティブ・意思決定 | 「2026-05-02 に Hybrid Memory 移行 epic を再開した」 |
| **summaries** | カテゴリ別サマリ = コンテキスト注入の第 1 層 | identity / work / preference 各カテゴリの要約 |

ファクトは原子的事実、エピソードは流れ・判断を保持する。両者を相補的に使う。

### Fact のフィールド

| フィールド | 値 |
|---|---|
| `source_entity_name` | 主語（必須） |
| `source_entity_type` | `person` / `organization` / `tool` / `concept` / `place` / `project` |
| `target_entity_name` | 目的語のエンティティ名（任意。値型なら省略） |
| `target_entity_type` | 同上の type |
| `relation_type` | snake_case の述語（例: `works_at`, `uses`, `develops`, `prefers`） |
| `content` | 人間可読な事実テキスト（必須） |
| `category` | `identity` / `work` / `preference` / `health` / `finance` / `technical` / `other` |
| `confidence` | `0.9`（明示的発話）/ `0.7`（文脈から推論）/ `0.5`（弱い推論） |

## ワークフロー

### 1. 参照 — 会話冒頭で必ず引く

会話の最初の応答**より前**に `search_knowledge` を呼ぶ。
- query には「吉野哲平」＋ 直近のタスクキーワードを混ぜる
- 結果の facts / episodes / summaries / entities を全て確認
- 取得情報は応答に自然に統合し、検索した事実自体は明示しない

会話中も関連しそうなら躊躇なく `search_knowledge` を再実行する。

### 2. 記録 — 事実を得たら同ターンで保存

`add_facts` で 1 件以上のファクトをまとめて保存する。
- `category` と `confidence` は**必ず付与**する（quality 担保のため）
- 同義の既存ファクトは自動で reinforce される（重複の心配なし）
- 矛盾は `action: "conflict"` で返るので `detect_conflicts` → `resolve_conflicts` で解消

**記録の判断基準**: 「次の会話で役立つか？」が唯一の基準。少しでも可能性があれば記録。

**記録しないもの**: パスワード・APIキー・トークン等の機密情報のみ。

### 3. エピソードの記録 — セッション終端で

会話の終わりや大きな決定の節目で `add_episode` を呼ぶ。
- `narrative`: その session で何が起きたかの要約
- `decision_point`: 最も重要な意思決定（あれば）
- `fact_ids` / `entity_ids`: そのエピソードが触れた実体への参照

### 4. 矛盾の解消

`search_knowledge` の結果に矛盾が見えたら:
1. `detect_conflicts(entity_id)` で意味的に対立するファクト群を取得
2. 正しい方の `keep_id` と古い方の `expire_ids` を決め `resolve_conflicts` で expire

## ツールリファレンス（新ツール = 推奨）

### add_facts
| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| facts | array | yes | 上記「Fact のフィールド」の dict 配列 |
| source | string | no | ソース識別子（デフォルト: `mcp`） |

### search_knowledge
| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| query | string | yes | 自然言語の検索クエリ |
| include_expired | bool | no | 期限切れ事実も含めるか（デフォルト: false） |

### add_episode
| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| narrative | string | yes | セッション要約 |
| decision_point | string | no | 最重要の意思決定 |
| fact_ids | array | no | 関連 fact の ID |
| entity_ids | array | no | 関連 entity の ID |

### detect_conflicts
| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| entity_id | string | yes | 対象エンティティの Firestore ID |

### resolve_conflicts
| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| keep_id | string | yes | 残す fact の ID |
| expire_ids | array | yes | expire する fact の ID 配列 |

## レガシーツール（DEPRECATED — 2026-06-15 削除予定）

`add_triples` / `search_triples` / `search_memory` / `delete_triples` / `cleanup_duplicates` は旧トリプル実装。**読み書きとも禁止**。

- データは Phase 2 (#56) で `facts` / `entities` に移行済みなので、`search_knowledge` で全て引ける
- 削除タスク: リポ側 issue #46（Phase 4 コード削除）で実施
- 万一 LLM が legacy ツール名を提案してきても呼ばないこと

## 重要事項

- **サイレント動作**: メモリ操作をユーザーに通知しない
- **プライバシー**: パスワード、APIキー、機密情報は保存しない
- **ユーザー問い合わせ**: 「何を覚えているか」と聞かれたら `search_knowledge` を使用
- **trust score**: `search_knowledge` 結果は trust（confidence × recency × 言及数）で並ぶ。古い・自信の低い事実は自然に下位に来るので過剰に削除しないこと
