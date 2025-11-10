# Project Context

## Tech Stack

### Frontend
- **Framework**: SvelteKit + Svelte
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: shadcn-svelte
- **Build Tool**: Vite
- **Package Manager**: pnpm

#### SvelteKit Development Guidelines

**Server-Side Rendering (SSR) First:**
- Maximize SSR wherever possible - leverage SvelteKit's SSR capabilities
- Push implementation to the server side and minimize client-side processing
- Use `+page.server.ts` for data loading and server-side logic
- Prefer `load` functions in `+page.server.ts` over `+page.ts` when data can be fetched server-side
- Use form actions for mutations instead of client-side API calls

**SEO Optimization:**
- Always set appropriate meta tags (title, description, og tags) in `+page.svelte` or `+layout.svelte`
- Use semantic HTML elements
- Ensure proper heading hierarchy (h1, h2, h3, etc.)
- Implement structured data (JSON-LD) where applicable
- Generate sitemaps for public pages
- Use `prerender = true` for static pages when possible
- Optimize images with proper alt text and lazy loading

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
5. **Implement services as classes, not as standalone functions** - Services should be defined as classes with methods, enabling better encapsulation, dependency injection, and testability

### Documentation and Diagrams

**ALWAYS maintain ER diagrams and sequence diagrams** in `docs/diagrams/` using Mermaid format:

1. **When creating new features:**
   - Create corresponding ER diagrams for data models in `docs/diagrams/er/`
   - Create sequence diagrams for complex workflows in `docs/diagrams/sequence/`

2. **When modifying existing implementations:**
   - **Update the corresponding diagrams** to reflect the changes
   - Ensure diagrams stay in sync with the actual implementation

3. **Diagram requirements:**
   - Use Mermaid syntax for all diagrams
   - Include clear titles and descriptions
   - Keep diagrams focused and readable
   - Organize by feature or domain area

Example file structure:
```
docs/
  diagrams/
    er/
      user-domain.mmd
      order-domain.mmd
    sequence/
      user-registration.mmd
      order-processing.mmd
```

### Cloud Resource Management

**NEVER delete cloud resources directly.** When cloud resources (BigQuery datasets/tables, Cloud Storage buckets, etc.) need to be recreated or modified:

1. **Create a backup first** - Export or snapshot the existing resource
2. **Verify the backup** - Ensure the backup is complete and accessible
3. **Only then proceed with deletion** - After confirmation that backup is safe
4. **Document the backup location** - Note where the backup is stored for recovery

This applies to all cloud resources including but not limited to:
- BigQuery datasets and tables
- Cloud Storage buckets and objects
- Database instances
- VM instances with persistent data
- Any stateful cloud resources
