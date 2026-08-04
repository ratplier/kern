--!strict

const scope_types = require("@kern/scope")
const syntax_types = require("@kern/syntax/types")
const query_types = require("@kern/query/types")
const require_types = require("@kern/require")

export type TransformPhase = "syntax" | "module" | "finalize"

export type TransformContext = {
	source: string,
	file_path: string,
	project_root: string,
	resolved_requires: { require_types.ResolvedRequire }?,
	replace: (self: TransformContext, target: syntax_types.SyntaxNode, replacement: syntax_types.SyntaxNode) -> (),
	remove: (self: TransformContext, target: syntax_types.SyntaxNode) -> (),
	replace_range: (self: TransformContext, target: syntax_types.Span, replacement: string) -> (),
	remove_range: (self: TransformContext, target: syntax_types.Span) -> (),
	insert_before: (self: TransformContext, target: syntax_types.SyntaxNode | syntax_types.Span, source: string) -> (),
	insert_after: (self: TransformContext, target: syntax_types.SyntaxNode | syntax_types.Span, source: string) -> (),
	insert_import: (self: TransformContext, source: string) -> (),
	ensure_import: (self: TransformContext, binding: string, request: string) -> boolean,
}

export type TransformDefinition = {
	phase: TransformPhase?,
	scope: scope_types.Scope?,
	run: (tree: query_types.SyntaxRoot, context: TransformContext) -> (),
}

export type TransformRule = {
	kind: "transform",
	name: string,
	phase: TransformPhase,
	scope: scope_types.Scope?,
	run: (tree: query_types.SyntaxRoot, context: TransformContext) -> (),
}

local transform = {}

const function validate_phase(value: string): TransformPhase
	if value == "syntax" then
		return "syntax"
	end
	if value == "module" then
		return "module"
	end
	if value == "finalize" then
		return "finalize"
	end

	error(`kern: invalid transform phase '{value}'`, 2)
end

const function new(name: string, definition: TransformDefinition): TransformRule
	if name == "" then
		error("kern: transform rule name cannot be empty", 2)
	end

	const phase = validate_phase(definition.phase or "syntax")

	return {
		kind = "transform",
		name = name,
		phase = phase,
		scope = definition.scope,
		run = definition.run,
	}
end

transform.new = new

return transform
