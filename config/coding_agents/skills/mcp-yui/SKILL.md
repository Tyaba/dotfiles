---
name: mcp-yui
description: yui は会話履歴の圧縮版。対話から得た事実をRDFトリプルとして蓄積し、会話を跨いで長期記憶を提供する。
---

# yui MCP — 会話履歴の圧縮版

yui は対話全体を圧縮し、事実の羅列として永続化するナレッジグラフである。
会話が終われば LLM は全てを忘れるが、yui に保存された事実は次の会話で復元される。

## データモデル

事実は (subject, predicate, object) のトリプルとして保存される：
- **subject**: エンティティ識別子（例: `吉野哲平`, `ProjectAlpha`）
- **predicate**: snake_case、能動態の関係性（例: `uses`, `lives_in`, `develops`）
- **object**: 値または対象エンティティ（例: `Cursor`, `東京`）

1つのトリプル = 1つの原子的事実。

## ワークフロー

### 1. 参照（積極的に引き出せ）
- 会話開始時に `search_memory` でユーザー「吉野哲平」と関連トピックを検索
- 会話中も少しでも関連しそうなら躊躇なく `search_memory` を呼ぶ
- 取得した情報は自然に応答に統合し、検索した事実自体を明示しない

### 2. 記録（迷ったら記録せよ）
- 「次の会話で役立つか？」が唯一の基準。少しでも可能性があれば記録する
- 対話中に得た事実を `add_triples` で保存
- 既存の事実が変わったら `delete_triples` → `add_triples` で置換

**記録しないもの**: パスワード・APIキー・トークン等の機密情報のみ

## ツールリファレンス

### add_triples
トリプルをナレッジグラフに追加する。

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| triples | array | yes | `{subject, predicate, object}` の配列 |
| source | string | no | ソース識別子（デフォルト: `mcp`） |

### search_memory
自然言語クエリによるセマンティックベクトル検索。

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| query | string | yes | 自然言語の検索クエリ |

### search_triples
subject / predicate / object の完全一致フィルタで検索。空文字はフィルタなし。

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| subject | string | no | subject フィルタ |
| predicate | string | no | predicate フィルタ |
| object_value | string | no | object フィルタ |

### delete_triples
条件に一致するトリプルを削除する。少なくとも1つのフィルタが必要。

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| subject | string | no | subject フィルタ |
| predicate | string | no | predicate フィルタ |
| object_value | string | no | object フィルタ |

### cleanup_duplicates
重複トリプルを削除し、各グループの最新エントリを保持する。引数なし。

## リソース

| URI | 説明 |
|---|---|
| `graph://all` | ナレッジグラフ全体を JSON で返す |

## 重要事項

- **サイレント動作**: メモリ操作をユーザーに通知しない
- **プライバシー**: パスワード、APIキー、機密情報は保存しない
- **ユーザー問い合わせ**: 「何を覚えているか」と聞かれたら `search_memory` を使用
