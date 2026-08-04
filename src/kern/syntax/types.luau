--!strict

const syntax = require("@std/syntax")

export type Span = {
	start: number,
	finish: number,
}

export type SourceLocation = {
	line: number,
	column: number,
}

export type SyntaxTree = syntax.ParseResult
export type SyntaxNode = syntax.AstNode
export type SyntaxRoot = syntax.AstStatBlock
export type SyntaxExpression = syntax.AstExpr

export type ParseSuccess = {
	ok: true,
	tree: SyntaxTree,
}

export type ParseFailure = {
	ok: false,
	error: ParseError,
}

export type ParseResult = ParseSuccess | ParseFailure

export type ParseError = {
	code: "parse_error",
	message: string,
	file_path: string?,
	line: number?,
	column: number?,
	span: Span?,
}

return nil
