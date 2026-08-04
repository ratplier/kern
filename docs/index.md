---
sidebar_position: 1
slug: /
---

# kern

kern is a pure-Luau project tool for linting, AST transforms, require rewriting,
and deterministic output.

## Start here

- [Getting started](guides/getting-started.md) — install with Rokit, build from source, and create a project.
- [Projects and components](guides/projects.md) — compose reusable pipeline behavior.
- [Transforms](guides/transforms.md) — query, quote, replace, and import safely.
- [Output and Rojo](guides/output.md) — emit source and assets for a game project.

## Reference and maintenance

- [API reference](api/index.md) — JSON-backed public API pages grouped by section.
- [CLI workflows](guides/cli.md) — command usage and a safe local gate.
- [Writing API docs](maintainers/writing-api-docs.md) — public `--[=[ ... ]=]` docs.
- [CI and releases](maintainers/ci-cd.md) — verification and native artifact publishing.

Run `lute run scripts/generate_docs.luau` after changing public typedef docs.
