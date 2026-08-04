--!nocheck

const syntax = require("@std/syntax")

--[=[
	@within Syntax

	A half-open byte range in Luau source.
]=]
export type Span = { start: number, finish: number }

--[=[
	@within Syntax

	A one-based position in Luau source.
]=]
export type SourceLocation = { line: number, column: number }

--[=[
	@within Syntax

	The syntax tree returned by Lute's Luau parser.
]=]
export type SyntaxTree = syntax.ParseResult
--[=[
	@within Syntax

	Any Luau AST node.
]=]
export type SyntaxNode = syntax.AstNode
--[=[
	@within Syntax

	The root statement block of a parsed Luau file or quoted block.
]=]
export type SyntaxRoot = syntax.AstStatBlock
--[=[
	@within Syntax

	Any Luau expression node.
]=]
export type SyntaxExpression = syntax.AstExpr

--[=[
	@within Syntax

	An error produced while parsing Luau source.
]=]
export type ParseError = {
	code: "parse_error",
	message: string,
	file_path: string?,
	line: number?,
	column: number?,
	span: Span?,
}

--[=[
	@within Syntax

	The result of parsing Luau source.
]=]
export type ParseResult = { ok: true, tree: SyntaxTree } | { ok: false, error: ParseError }

return {}
