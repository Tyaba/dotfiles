@~/.claude/user-rules.md
@AGENTS.md

# Claude Code 固有設定

## サブエージェント利用

以下のケースではTaskツールで積極的にサブエージェントを活用せよ：
- **大規模なコード探索**: 複数のディレクトリにまたがる調査が必要な場合（Exploreエージェント）
- **並列作業**: 複数の独立したタスク（例：コード修正とドキュメント更新）を同時に進める場合
- **TDDサイクル**: `/red`, `/green`, `/refactor` カスタムコマンドを使用

### Git 操作を伴う並列サブエージェント

複数のサブエージェントが**異なるブランチ**で作業する場合、必ず `isolation: "worktree"` を指定せよ。
同一ワーキングディレクトリで並列に `git checkout` すると互いのブランチ操作が競合し、commit/push が失敗する。

## TDD

関数やクラス等の実装を追加するとき、`/red` → `/green` → `/refactor` の順にカスタムコマンドを実行せよ。各フェーズの完了時にコミットを行う。

## MCP（Claude Code 固有）

AGENTS.md の MCP 一覧に加えて以下も利用せよ：
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
