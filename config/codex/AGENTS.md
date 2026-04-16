# Global AGENTS.md for Codex

## Language

Respond in 日本語.

## Working Agreements

- Do not commit unless the user explicitly asks.
- Do not delete cloud resources directly (BigQuery, Cloud Storage, Database instances, VM instances, etc.). Always follow: backup -> verify -> delete.
- Do not add comments that just narrate what the code does. Comments should only explain non-obvious intent, trade-offs, or constraints.

## Language & Framework Rules

### Python
- Use `uv` for running Python and managing packages.
- Use `pytest` for tests (not unittest). Use pytest mock (not unittest.mock).
- Use `ruff` for linting and formatting.
- Use `ty` for type checking.

### Frontend (TypeScript / React / Next.js)
- Use `pnpm` for package management.
- Use `Biome` for linting and formatting.
- Use `Vitest` for unit tests, `Playwright` for E2E tests.

### Infrastructure
- Use `Terraform` for IaC.
- Never run `terraform destroy` or `terraform apply -auto-approve`.
