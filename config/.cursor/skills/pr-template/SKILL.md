---
name: pr-template
description: PR作成時にAI監査情報を含むPR descriptionを生成する。PR作成を依頼された際に使用する。
---

# PR Template Skill

PR作成（`gh pr create`）時に、PR description を生成する。

## フロー

1. `git log` と `git diff` で変更内容を把握する
2. リポジトリに PR テンプレート（`.github/pull_request_template.md` 等）が存在するか確認する
3. テンプレートの選択:
   - **リポジトリ側テンプレートがある場合**: そのテンプレートに従って各セクションを埋める。加えて、AI監査セクション（Assumptions / Intent Mapping / Confidence / Behavior / Flow Diagram）を `<details><summary>AI監査</summary>...</details>` の折りたたみ形式で「変更内容」の直後に差し込む
   - **リポジトリ側テンプレートがない場合**: [TEMPLATE.md](TEMPLATE.md) に従って各セクションを埋める（AI監査は通常の見出しで出力）
4. `gh pr create --title "..." --body "$(cat <<'EOF' ... EOF)"` で PR を作成する

## AI監査セクションの出力判断

| 変更の種類 | AI監査セクション |
|---|---|
| 新機能追加 | 全項目出力 |
| ビジネスロジック変更 | 全項目出力 |
| アーキテクチャ変更 | 全項目出力 |
| バグ修正 | 省略可 |
| リファクタリング | 省略可 |
| ドキュメントのみ | 省略 |

省略する場合は `## AI監査` セクション自体を含めない。

### Flow Diagram の出力判断

以下のいずれかに該当する場合、AI監査内に `### Flow Diagram（処理フロー図）` を mermaid で出力する。

- 外部 API・マイクロサービス間の通信フローが変更・追加された
- 非同期処理（キュー、イベント、バッチ）のフローが変更・追加された
- 複数コンポーネント/レイヤーをまたぐ処理パイプラインが変更・追加された
- 状態遷移が複雑なロジック（ステートマシン等）が変更・追加された

該当しない単純な変更では省略する。図の種類は処理の性質に応じて `sequenceDiagram`、`flowchart`、`stateDiagram-v2` 等を使い分ける。

## 注意事項

- Issue番号が不明な場合はユーザーに確認する
- Assumptions は「AIが知らなかったこと」を正直に列挙する。見栄えのために省略しない
- Confidence で「要確認」がある場合、PR作成前にユーザーに確認を取る
