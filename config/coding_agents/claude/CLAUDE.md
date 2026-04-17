@~/.claude/user-rules.md
@AGENTS.md

# Claude Code 固有設定

## Codex オフロード（最優先のチェックポイント）

`user-rules.md` の「Codex オフロード」節に従い、**コード変更を伴うタスクはデフォルトで `mcp__codex__codex` に移譲する**。

Claude Code 固有の注意：

- `Edit` / `Write` / `NotebookEdit` を**初めて呼ぶ前に** 着手前ゲートの自問を行う。ツール呼び出しを開始してから「やっぱり Codex」では遅い。
- Task サブエージェント（Explore 等）と Codex の使い分け：
  - **Task サブエージェント**: 読み取り中心のコード探索・調査
  - **Codex (`mcp__codex__codex`)**: コード変更・テスト作成・lint 修正など書き込み系
- `/red`, `/green`, `/refactor` の各フェーズ内の実装そのものも Codex に移譲可。サイクルの進行は Claude が担う。
- CLAUDE.md / user-rules.md / settings.json / skills など**ルール・設定ファイルの編集は Claude 残留**（「Claude に残すタスク」に該当）。

## サブエージェント利用

以下のケースではTaskツールで積極的にサブエージェントを活用せよ：
- **大規模なコード探索**: 複数のディレクトリにまたがる調査が必要な場合（Exploreエージェント）
- **並列作業**: 複数の独立したタスク（例：コード修正とドキュメント更新）を同時に進める場合
- **TDDサイクル**: `/red`, `/green`, `/refactor` カスタムコマンドを使用

### Git 操作を伴う並列サブエージェント

複数のサブエージェントが**異なるブランチ**で作業する場合、必ず `isolation: "worktree"` を指定せよ。
同一ワーキングディレクトリで並列に `git checkout` すると互いのブランチ操作が競合し、commit/push が失敗する。

## TDD

関数やクラス等の実装を追加するとき、`/red` → `/green` → `/refactor` の順にカスタムコマンドを実行せよ。各フェーズの完了時にコミットを行う。各フェーズの実装自体は Codex オフロード対象である。

## MCP（Claude Code 固有）

AGENTS.md の MCP 一覧に加えて以下も利用せよ：
- **codex** (`mcp__codex__codex`): コード変更系タスクのデフォルト移譲先。上記「Codex オフロード」セクション参照
- **context7**: ライブラリの最新ドキュメント・構文確認

## Tech Stack

### Frontend
- **Framework**: Next.js (App Router) + React
- **Language**: TypeScript
- **Styling**: Tailwind CSS v4
- **UI Components**: shadcn/ui (Radix UI)
- **Linting**: Biome
- **Testing**: Vitest + Playwright (E2E)
- **Package Manager**: pnpm

#### Next.js Development Guidelines

**Server Components First:**
- React Server Components をデフォルトで使用し、サーバーサイドに処理を寄せる
- `"use client"` は必要最小限のコンポーネントにのみ付与する

**SEO Optimization:**
- Metadata API, semantic HTML, heading hierarchy, structured data (JSON-LD), sitemaps, image optimization

### Backend
- **Language**: Python >= 3.14
- **Framework**: FastAPI (Uvicorn / Gunicorn)
- **Linting / Formatting**: Ruff
- **Type Checking**: ty
- **Testing**: pytest + pytest-cov
- **DI**: Injector
- **Package Manager**: uv

### Infrastructure
- **Cloud**: Google Cloud
- **IaC**: Terraform
- **CI/CD**: Cloud Build + GitHub Actions
- **Container**: Docker (Debian slim + uv)
