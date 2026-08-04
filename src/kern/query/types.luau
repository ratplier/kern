--!strict

const syntax = require("@std/syntax")

export type SyntaxRoot = syntax.AstStatBlock
export type SyntaxNode = syntax.AstNode
export type SyntaxExpression = syntax.AstExpr
export type Span = {
	start: number,
	finish: number,
}
export type Matcher = (node: SyntaxNode) -> boolean
export type Normalizer<Result> = (node: SyntaxNode) -> Result
export type Filter<Result> = (value: Result) -> boolean

export type Query<Result> = {
	visit: (self: Query<Result>, root: SyntaxRoot) -> () -> Result?,
	each: (self: Query<Result>, root: SyntaxRoot, callback: (Result) -> ()) -> (),
	collect: (self: Query<Result>, root: SyntaxRoot) -> { Result },
	where: (self: Query<Result>, predicate: Filter<Result>) -> Query<Result>,
	filter: (self: Query<Result>, predicate: Filter<Result>) -> Query<Result>,
	where_all: (self: Query<Result>, predicates: { Filter<Result> }) -> Query<Result>,
	where_any: (self: Query<Result>, predicates: { Filter<Result> }) -> Query<Result>,
	where_none: (self: Query<Result>, predicates: { Filter<Result> }) -> Query<Result>,
	where_not: (self: Query<Result>, predicate: Filter<Result>) -> Query<Result>,
}

return nil
