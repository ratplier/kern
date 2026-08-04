---
sidebar_position: 4
title: Syntax and queries
---

<!-- Generated from api.json by scripts/render_api_docs.luau. Do not edit directly. -->

Parse Luau, create source nodes, and inspect syntax with queries.

## API

### `calls.any`

```luau
calls.any = nil :: Query<CallInfo>
```

Matches every function and method call.

### `calls.argument_count_between`

```luau
function calls.argument_count_between(minimum: number, maximum: number): Query<CallInfo>
```

Matches calls whose argument count is within an inclusive range.

**Parameters**

- `minimum` — The inclusive minimum argument count
- `maximum` — The inclusive maximum argument count

**Returns:** A reusable call query

### `calls.global`

```luau
function calls.global(name: string): Query<CallInfo>
```

Matches calls to a global function with the given name.

**Parameters**

- `name` — The global function name

**Returns:** A cached call query

### `calls.member`

```luau
function calls.member(name: string?): Query<CallInfo>
```

Matches non-global member calls, optionally restricted to a member name.

**Parameters**

- `name` — An optional member name

**Returns:** A cached call query

### `calls.method`

```luau
function calls.method(name: string?): Query<CallInfo>
```

Matches method calls, optionally restricted to a method name.

**Parameters**

- `name` — An optional method name

**Returns:** A cached call query

### `calls.with_argument_count`

```luau
function calls.with_argument_count(count: number): Query<CallInfo>
```

Matches calls with exactly `count` arguments.

**Parameters**

- `count` — The required argument count

**Returns:** A cached call query

### `calls.with_maximum_arguments`

```luau
function calls.with_maximum_arguments(maximum: number): Query<CallInfo>
```

Matches calls with at most `maximum` arguments.

**Parameters**

- `maximum` — The maximum argument count

**Returns:** A reusable call query

### `calls.with_minimum_arguments`

```luau
function calls.with_minimum_arguments(minimum: number): Query<CallInfo>
```

Matches calls with at least `minimum` arguments.

**Parameters**

- `minimum` — The minimum argument count

**Returns:** A cached call query

### `compose.intersect`

```luau
function compose.intersect<Result>(first: Query.Query<Result>, second: Query.Query<Result>): Query.Query<Result>
```

Matches only values produced by both queries.

**Parameters**

- `first` — The first query
- `second` — The second query

**Returns:** The intersected query

### `compose.pipe`

```luau
function compose.pipe<Parent, Child>(parent: Query.Query<Parent>, child: Query.Query<Child>): Query.Query<Child>
```

Evaluates a child query after the parent query has matched.

**Parameters**

- `parent` — The outer query
- `child` — The query evaluated after the parent

**Returns:** The piped child query

### `compose.union`

```luau
function compose.union<Result>(first: Query.Query<Result>, second: Query.Query<Result>): Query.Query<Result>
```

Matches values produced by either query, without duplicates.

**Parameters**

- `first` — The first query
- `second` — The second query

**Returns:** The combined query

### `query.filters`

```luau
query.filters = nil :: {
```

Reusable predicates for narrowing query results.

Top-level filters compose predicates and compare selected values. Specialized
`string`, `number`, `array`, and `boolean` groups provide common predicates
without requiring a new callback for each query.

### `query.from_evaluator`

```luau
function query.from_evaluator<Result>(evaluator: (root: Types.SyntaxRoot) -> { Result }): Types.Query<Result>
```

Creates a query backed by a custom evaluator.

**Parameters**

- `evaluator` — Produces results from a syntax root

**Returns:** A reusable query

### `query.match`

```luau
query.match = nil :: {
```

Syntax-node matchers used to construct queries. Use `where` to add a custom
predicate to any existing matcher.

### `query.new`

```luau
function query.new<Result>(matchers: { Types.Matcher }, normalize: Types.Normalizer<Result>): Types.Query<Result>
```

Creates a query from matchers and a normalizer.

**Parameters**

- `matchers` — Predicates that select syntax nodes
- `normalize` — Converts a matching node into a result

**Returns:** A reusable query

## Types

### `FunctionParameter`

```luau
export type FunctionParameter = { name: string?, raw: Node }
```

A normalized function parameter and its original syntax node.

### `OperatorInfo`

```luau
export type OperatorInfo = { operator: string, is_binary: boolean, is_unary: boolean, span: Span, raw: Node }
```

Normalized metadata for a unary or binary operator expression.

### `ParseResult`

```luau
export type ParseResult = { ok: true, tree: SyntaxTree } | { ok: false, error: ParseError }
```

The result of parsing Luau source.

### `SourceLocation`

```luau
export type SourceLocation = { line: number, column: number }
```

A one-based position in Luau source.

### `Span`

```luau
export type Span = { start: number, finish: number }
```

A half-open byte range in Luau source.

### `SyntaxExpression`

```luau
export type SyntaxExpression = syntax.AstExpr
```

Any Luau expression node.

### `SyntaxNode`

```luau
export type SyntaxNode = syntax.AstNode
```

Any Luau AST node.

### `SyntaxRoot`

```luau
export type SyntaxRoot = syntax.AstStatBlock
```

The root statement block of a parsed Luau file or quoted block.

### `SyntaxTree`

```luau
export type SyntaxTree = syntax.ParseResult
```

The syntax tree returned by Lute's Luau parser.

### `TypeInfo`

```luau
export type TypeInfo = { kind: string, name: string?, is_export: boolean, span: Span, raw: Node }
```

Normalized metadata for a type annotation or declaration.

