---
name: mcp-memory
description: user-memory MCPサーバーを使用して、ユーザー情報、プロジェクト、関係性を会話を跨いで永続的に記憶する。ユーザーやプロジェクト、好みに関する情報収集時、または会話中に重要な新情報が現れた際に使用する。
---

# MCP メモリ管理

user-memory MCPサーバーを使用して永続的なメモリを自動管理する。

## 基本概念

### エンティティ
主要なノードで、以下を持つ：
- **name**: 一意な識別子
- **entityType**: person, organization, project, event, concept, location
- **observations**: 原子的な事実の配列

### 関係性
能動態での有向接続（例: "works_at", "develops", "manages"）

### 観察
文字列として保存される原子的な事実。1つの観察 = 1つの事実。

## ワークフロー

### 1. メモリ取得（会話開始時）
```
- search_nodes または open_nodes で既存のメモリを取得
- デフォルトユーザー: "吉野哲平"
- 取得した情報を自然に応答に統合（検索していることを明示しない）
```

### 2. 情報監視（会話中）
以下のカテゴリの新情報を監視：

**a) 基本情報**
- 年齢、性別、居住地、職業、学歴

**b) 行動**
- 興味、習慣、活動パターン

**c) 好み**
- コミュニケーションスタイル、言語、技術スタック、ツール

**d) 目標**
- 目的、ターゲット、aspirations

**e) 関係性**
- 個人的・職業的なつながり（3次の隔たりまで）

**f) プロジェクト**
- 開発プロジェクト、進捗、課題

**g) 健康**
- 健康状態、治療、症状

### 3. メモリ更新（各ターン終了前）

ルールのチェックリストでYESとなった項目に対し、以下のツールで対応する：

| チェック項目 | 操作 |
|---|---|
| 新しい事実 | `add_observations` で該当エンティティに追加 |
| 新しいエンティティ | `create_entities` で作成 |
| 新しい関係 | `create_relations` で接続 |
| 情報の変更 | `delete_observations` → `add_observations` で置換 |

**記録対象の判断基準:**

| 記録する | 記録しない |
|----------|------------|
| 確定した事実・決定 | 推測・仮説 |
| 繰り返し参照されそうな情報 | 一時的な会話の文脈 |
| プロジェクトの状態変化 | 既に記録済みの情報 |
| 個人の好み・習慣・目標 | パスワード・APIキー |

## エンティティ設計ガイドライン

### エンティティタイプ（必ず小文字の snake_case を使用）
- `person`: ユーザー、家族、同僚
- `organization`: 企業、グループ
- `project`: 開発プロジェクト、サービス
- `event`: 重要なイベント、マイルストーン
- `concept`: アイデア、方法論
- `location`: 場所、住所
- `tool`: ツール、サービス
- `issue`: バグ、課題
- `design_decision`: 設計判断
- `gcp_project`: GCPプロジェクト
- `component`: コンポーネント、モジュール

**禁止**: `Project`, `Domain`, `GCPProject` 等の PascalCase は使用しない

### 観察の原則
- **原子性**: 1つの観察に1つの事実
- **具体性**: 曖昧な表現を避ける
- **日付**: 時系列情報には日付を含める
- **事実性**: 確認済みの情報のみ
- **上限**: 1エンティティ 20 observations 以下を目安。超過時はエンティティを分割

### エンティティ分割ルール
observations が 20 を超えそうな場合、以下で分割:
- 技術構成 → `{project}-architecture`
- 設計判断 → `{project}-design-{topic}`
- 時系列イベント → `{project}-{YYYY-MM-DD}-{event}`
- 完了済みタスク → `{project}-{topic}`
- 分割後は `create_relations` で親エンティティと接続すること

### 関係性の原則
- **能動態**: "works_at"（"employed_by"ではなく）
- **明確性**: 関係性の種類を明示
- **方向性**: from/toの方向を適切に設定

## 例

### エンティティ作成
```json
{
  "name": "田中太郎",
  "entityType": "person",
  "observations": [
    "30歳、東京都在住",
    "ソフトウェアエンジニア（勤続5年）",
    "週末にオープンソース活動"
  ]
}
```

### 関係性作成
```json
{
  "from": "田中太郎",
  "to": "ProjectAlpha",
  "relationType": "develops"
}
```

### 観察追加
```json
{
  "entityName": "ProjectAlpha",
  "contents": [
    "2026年2月: テスト自動化完了",
    "ベータ版リリース準備中"
  ]
}
```

## 重要事項

- **サイレント動作**: メモリ操作をユーザーに通知しない
- **プライバシー**: パスワード、APIキー、機密情報は保存しない
- **検証**: 不確実な情報は記録前に確認
- **ユーザー問い合わせ**: 「何を覚えているか」と聞かれたら read_graph または search_nodes を使用

## ツールリファレンス

- `create_entities`: 観察を含む新しいエンティティを作成
- `create_relations`: エンティティ間を関係性で接続
- `add_observations`: 既存エンティティに事実を追加
- `search_nodes`: 名前、タイプ、観察を横断してクエリ検索
- `open_nodes`: 名前で特定のエンティティを取得
- `read_graph`: ナレッジグラフ全体を取得
- `delete_entities`: エンティティを削除（関係性もカスケード削除）
- `delete_observations`: 特定の観察を削除
- `delete_relations`: 特定の関係性を削除

## グラフメンテナンス

### 整理スクリプト
`~/ghq/github.com/Tyaba/vault/mcp_server_memory/cleanup_graph.py` でグラフの分析・整理を行う:
- `uv run python cleanup_graph.py`: レポート出力（ドライラン）
- `uv run python cleanup_graph.py --fix`: 安全な自動修正（重複observations/relations削除、entityType正規化）
- `uv run python cleanup_graph.py --merge 'keep' 'remove'`: 重複エンティティのマージ
