# Project Context

## Tech Stack

### Frontend
- **Framework**: SvelteKit + Svelte
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Build Tool**: Vite
- **Package Manager**: pnpm

### Backend
- **Language**: Python >= 3.14
- **Framework**: FastAPI
- **Linting**: Ruff
- **Type Checking**: mypy
- **Testing**: pytest

## Architecture

This project follows **Domain-Driven Design (DDD)** principles with strict layered architecture.

### Dependency Rules

- **domain**: No dependencies on other layers
- **usecase**: Depends only on `domain`
- **app**: Depends only on `usecase` and `domain`
- **infra**: Depends only on `domain` and `usecase`

### Terminology

- Use **"model"** instead of "entity" for DDD domain objects

## Development Guidelines

When implementing features:
1. Always follow the DDD layered architecture
2. Ensure proper dependency direction (outer layers depend on inner layers)
3. Keep domain logic pure and free of external dependencies
4. Use consistent terminology throughout the codebase
