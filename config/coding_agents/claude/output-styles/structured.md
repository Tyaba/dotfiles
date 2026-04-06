---
name: Structured
description: Cursor-like structured output with clear headings, visual separators, and diagrams rendered as ASCII art
keep-coding-instructions: true
---

# Output Formatting

Structure every response for terminal readability. Terminals render Markdown partially — bold, headers, and lists work, but tables and inline styles do not render well.

## Rules

1. **Use headings** (`##`, `###`) to separate logical sections of your response.
2. **Use bold** (`**text**`) for key terms, file names, and important values.
3. **Use bullet lists** for enumerating items, options, or steps. Prefer `-` over `*`.
4. **Use numbered lists** for sequential steps or ranked items.
5. **Use code blocks** with language tags for all code snippets.
6. **Use horizontal rules** (`---`) to visually separate major sections when the response is long.
7. **Avoid tables** — they render poorly in terminals. Use bullet lists or definition-style formatting instead.
8. **Keep lines short** — aim for under 100 characters per line in prose.

## Diagrams

When explaining architecture, data flow, or relationships:

1. **Prefer ASCII/Unicode box-drawing diagrams** rendered directly in code blocks. These display correctly in all terminals:

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client   │────▶│  Server  │────▶│    DB    │
└──────────┘     └──────────┘     └──────────┘
```

2. For **tree structures**, use the standard tree format:

```
src/
├── components/
│   ├── Button.tsx
│   └── Modal.tsx
├── hooks/
│   └── useAuth.ts
└── index.ts
```

3. For **flow/sequence**, use vertical arrow diagrams:

```
User Request
    │
    ▼
Authentication ──▶ 401 Unauthorized
    │
    ▼
Authorization  ──▶ 403 Forbidden
    │
    ▼
Handler
    │
    ▼
Response
```

4. When a diagram would be complex enough to benefit from rendering, **also** write the mermaid source to a `.mmd` file so the user can view it externally.

## Summary Pattern

At the end of multi-step responses, include a **TL;DR** or **Summary** section with the key takeaways.
