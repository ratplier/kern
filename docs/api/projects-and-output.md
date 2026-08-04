---
sidebar_position: 3
title: Projects and output
---

<!-- Generated from api.json by scripts/render_api_docs.luau. Do not edit directly. -->

Configure projects, module resolution, filesystems, and build output.

## API

### `output.directory`

```luau
output.directory = output.new
```

Creates a directory output emitter.

**Parameters**

- `config` — The output directory, selected artifacts, and write behavior

**Returns:** A directory output emitter

### `output.new`

```luau
function output.new(config: OutputConfig): OutputEmitter
```

Creates a directory output emitter.

**Parameters**

- `config` — The output directory, selected artifacts, and write behavior

**Returns:** A directory output emitter

### `project.new`

```luau
function project.new(config: ProjectConfig): Project
```

Creates a project from source paths and reusable components.

**Parameters**

- `config` — Source paths, components, filesystem, output, and diagnostic policy

**Returns:** The configured project

### `resolver.new`

```luau
function resolver.new(config: RequireConfig): RequireResolver
```

Creates a module resolver.

**Parameters**

- `config` — Aliases, extensions, index names, and resolution behavior

**Returns:** The configured module resolver

### `resolver.scan`

```luau
function resolver.scan(source: string): Result.Result<{ RequireRequest }, RequireError>
```

Finds supported require calls in Luau source.

**Parameters**

- `source` — The Luau source to inspect

**Returns:** The discovered require calls or a structured parse error

## Types

### `DiagnosticPolicy`

```luau
export type DiagnosticPolicy = { minimum_failure_severity: Lint.Severity }
```

Controls which diagnostics make a project operation fail.
