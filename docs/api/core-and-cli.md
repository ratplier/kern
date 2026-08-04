---
sidebar_position: 5
title: Core and CLI
---

<!-- Generated from api.json by scripts/render_api_docs.luau. Do not edit directly. -->

CLI helpers and the result, graph, and error primitives behind Kern.

## API

### `cli.exit_code`

```luau
function cli.exit_code(value: RunResult): number
```

Returns the process exit code for a command result.

**Parameters**

- `value` — The command result

**Returns:** Its process exit code

### `cli.parse`

```luau
function cli.parse(values: { string }): ParseResult
```

Parses Kern command arguments without running a project.

**Parameters**

- `values` — Command-line argument values

**Returns:** The parsed arguments or a validation error

### `cli.render`

```luau
function cli.render(value: RunResult): string
```

Formats a command result for terminal output.

**Parameters**

- `value` — The command result to render

**Returns:** Human-readable terminal output

### `cli.run`

```luau
function cli.run(project: Project.Project, values: Arguments): RunResult
```

Runs a parsed command against a Kern project.

**Parameters**

- `project` — The project to operate on
- `values` — Parsed command arguments

**Returns:** The command result and process exit code

### `cli.usage`

```luau
function cli.usage(): string
```

Returns command-line usage text.

**Returns:** Command-line usage text

## Types

### `Err`

```luau
export type Err<Failure> = { ok: false, error: Failure }
```

A failed operation result.

### `Ok`

```luau
export type Ok<Value> = { ok: true, value: Value }
```

A successful operation result.

### `ParseResult`

```luau
export type ParseResult = { ok: true, value: Arguments } | { ok: false, error: string }
```

The result of parsing command-line arguments.

### `Result`

```luau
export type Result<Value, Failure> = Ok<Value> | Err<Failure>
```

A result that must be narrowed through its `ok` field.

