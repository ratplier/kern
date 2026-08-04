---
sidebar_position: 2
title: Authoring
---

<!-- Generated from api.json by scripts/render_api_docs.luau. Do not edit directly. -->

Create components, rules, transforms, and scoped tooling.

## API

### `component.new`

```luau
function component.new(name: string, members: { ComponentMember }): Component
```

Groups related lint rules, transforms, require resolvers, and output emitters.

**Parameters**

- `name` — A unique name for the component
- `members` — Rules and project services included in the component

**Returns:** The reusable component

### `kern.calls`

```luau
kern.calls = Calls
```

Queries for function and method calls.

### `kern.comments`

```luau
kern.comments = Catalog.comments
```

Queries for source comments.

### `kern.component`

```luau
function kern.component(name: string, members: { ComponentMember }): Component
```

Groups related lint rules, transforms, require resolvers, and output emitters.

**Parameters**

- `name` — A unique name for the component
- `members` — Rules and services included in the component

**Returns:** The reusable component

### `kern.compose`

```luau
kern.compose = Compose
```

Helpers for composing query matchers and normalizers.

### `kern.control_flow`

```luau
kern.control_flow = Catalog.control_flow
```

Queries for branches, loops, and control-flow statements.

### `kern.filters`

```luau
kern.filters = QueryModule.filters
```

Predicates for narrowing query results.

### `kern.functions`

```luau
kern.functions = Catalog.functions
```

Queries for function declarations and expressions.

### `kern.lint`

```luau
function kern.lint(name: string, definition: LintDefinition): LintRule
```

Creates a named lint rule from a rule definition.

**Parameters**

- `name` — A unique rule name
- `definition` — The rule callback, severity, scope, and description

**Returns:** The validated lint rule

### `kern.locals`

```luau
kern.locals = Catalog.locals
```

Queries for local declarations and references.

### `kern.match`

```luau
kern.match = QueryModule.match
```

Helpers for matching syntax nodes.

### `kern.modules`

```luau
kern.modules = Catalog.modules
```

Queries for module-related syntax.

### `kern.operators`

```luau
kern.operators = Catalog.operators
```

Queries for unary and binary operators.

### `kern.output`

```luau
kern.output = Output
```

Output emitter constructors, including `directory`.

### `kern.parse`

```luau
function kern.parse(source: string, file_path: string?): Syntax.ParseResult
```

Parses a complete Luau source file.

**Parameters**

- `source` — The Luau source to parse
- `file_path` — Optional path included in parse errors

**Returns:** The parsed syntax tree or a structured parse error

### `kern.parse_block`

```luau
function kern.parse_block(source: string): Syntax.ParseResult
```

Parses a sequence of Luau statements.

**Parameters**

- `source` — The Luau statements to parse

**Returns:** The parsed syntax tree or a structured parse error

### `kern.parse_expression`

```luau
function kern.parse_expression(source: string): Syntax.ParseResult
```

Parses one Luau expression.

**Parameters**

- `source` — The Luau expression to parse

**Returns:** The parsed syntax tree or a structured parse error

### `kern.project`

```luau
function kern.project(config: ProjectConfig): Project
```

Creates a project that can lint, transform, check, or build Luau files.

**Parameters**

- `config` — Source paths, components, filesystem, and output settings

**Returns:** The configured project

### `kern.query`

```luau
function kern.query<Result>(config: QueryConfig<Result>): Query<Result>
```

Creates a reusable syntax query from matchers and a normalizer.

**Parameters**

- `config` — Matchers and a function that normalizes matching nodes

**Returns:** A reusable query of normalized results

### `kern.quote`

```luau
function kern.quote(source: string): Syntax.SyntaxNode
```

Creates a syntax node from Luau source. A single statement produces that
statement node, multiple statements produce a block, and expression source
produces an expression node.

The returned node can be passed directly to transform operations such as
`context:replace(target, kern.quote("local answer = 40"))`.

Throws an error when `source` is empty or is not valid Luau.

**Parameters**

- `source` — The Luau statement, statements, or expression to quote

**Returns:** The generated syntax node

### `kern.quote_block`

```luau
function kern.quote_block(source: string): Syntax.SyntaxRoot
```

Creates a block node from a sequence of Luau statements.

Throws an error when `source` is not valid Luau.

**Parameters**

- `source` — The Luau statements to quote

**Returns:** The generated statement block

### `kern.quote_expression`

```luau
function kern.quote_expression(source: string): Syntax.SyntaxExpression
```

Creates an expression node from Luau source.

Throws an error when `source` is not exactly one valid Luau expression.

**Parameters**

- `source` — The Luau expression to quote

**Returns:** The generated expression node

### `kern.require`

```luau
function kern.require(config: RequireConfig): RequireResolver
```

Creates the module resolver used to inspect and rewrite require calls.

**Parameters**

- `config` — Aliases and module resolution behavior

**Returns:** The configured require resolver

### `kern.scope`

```luau
function kern.scope(config: ScopeConfig): Scope
```

Creates a comment-directive scope used to suppress rules or transforms.

**Parameters**

- `config` — The directive namespace and binding names

**Returns:** The configured scope

### `kern.strings`

```luau
kern.strings = Catalog.strings
```

Queries for string expressions.

### `kern.tables`

```luau
kern.tables = Catalog.tables
```

Queries for table constructors and fields.

### `kern.transform`

```luau
function kern.transform(name: string, definition: TransformDefinition): TransformRule
```

Creates a named source transform from a transform definition.

**Parameters**

- `name` — A unique transform name
- `definition` — The transform callback, phase, and scope

**Returns:** The validated transform

### `kern.types`

```luau
kern.types = Catalog.types
```

Queries for type declarations and annotations.

### `lint.compare`

```luau
function lint.compare(left: Diagnostic, right: Diagnostic): boolean
```

Orders two diagnostics deterministically by file and source position.

**Parameters**

- `left` — The first diagnostic
- `right` — The second diagnostic

**Returns:** Whether `left` sorts before `right`

### `lint.context`

```luau
function lint.context(
```

Creates a lint context for a source file.

**Parameters**

- `source` — The source being linted
- `file_path` — The source file path
- `project_root` — The owning project root
- `rule` — The active lint rule
- `component_name` — The component containing the rule
- `scope_map` — Parsed suppressions for the source

**Returns:** A context that reports diagnostics

### `lint.meets_severity`

```luau
function lint.meets_severity(severity: Severity, minimum: Severity): boolean
```

Returns whether a severity meets a configured minimum severity.

**Parameters**

- `severity` — The diagnostic severity
- `minimum` — The minimum accepted severity

**Returns:** Whether the diagnostic meets the threshold

### `lint.new`

```luau
function lint.new(name: string, definition: LintDefinition): LintRule
```

Creates a named lint rule.

**Parameters**

- `name` — A unique rule name
- `definition` — The callback and optional rule settings

**Returns:** The validated lint rule

### `scope.new`

```luau
function scope.new(config: ScopeConfig): Scope
```

Creates a comment-directive scope.

**Parameters**

- `config` — The directive namespace and binding names

**Returns:** The configured scope

### `scope.parse`

```luau
function scope.parse(source: string, value: Scope): Result.Result<ScopeMap, ScopeError>
```

Parses all configured directives in a source file.

**Parameters**

- `source` — The source containing directives
- `value` — The scope configuration to apply

**Returns:** The suppression map or a structured scope error

### `transform.new`

```luau
function transform.new(name: string, definition: TransformDefinition): TransformRule
```

Creates a named source transform.

**Parameters**

- `name` — A unique transform name
- `definition` — The callback, phase, and optional scope

**Returns:** The validated transform

## Types

### `ScopeBinding`

```luau
export type ScopeBinding = "next" | "range" | "range_end" | "file"
```

How a source directive selects the code it suppresses.

### `ScopeError`

```luau
export type ScopeError = { code: "scope_error", message: string, span: Syntax.Span? }
```

A malformed or misplaced scope directive.

### `Severity`

```luau
export type Severity = "hint" | "info" | "warn" | "error"
```

The severity assigned to a lint diagnostic.

### `Severity`

```luau
export type Severity = "hint" | "info" | "warn" | "error"
```

The severity assigned to a lint diagnostic.

### `Suppression`

```luau
export type Suppression = { namespace: string, start: number, finish: number }
```

A source range suppressed by a scope directive.

### `TransformPhase`

```luau
export type TransformPhase = "syntax" | "module" | "finalize"
```

The stage at which a transform runs.
