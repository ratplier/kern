--!nocheck

const Query = require("@kern/query/types")
const Require = require("@kern/require")
const Scope = require("@kern/scope")
const Syntax = require("@kern/syntax/types")

--[=[
	@within Transform

	The stage at which a transform runs.
]=]
export type TransformPhase = "syntax" | "module" | "finalize"

--[=[
	@within Transform

	Source information and edit operations available to a transform.

	`insert_import` inserts source after leading file comments and directives while
	preserving them at the beginning of the file.
	`ensure_import` inserts a conventional `const` require only when the binding and
	request are not already imported.

	`replace` and `remove` accept syntax nodes so edits stay aligned with the AST.
	Use `replace_range` or `remove_range` when an intentionally raw source span is
	more appropriate.
]=]
export type TransformContext = {
	source: string,
	file_path: string,
	project_root: string,
	resolved_requires: { Require.ResolvedRequire }?,
	replace: (self: TransformContext, target: Syntax.SyntaxNode, replacement: Syntax.SyntaxNode) -> (),
	remove: (self: TransformContext, target: Syntax.SyntaxNode) -> (),
	replace_range: (self: TransformContext, target: Syntax.Span, replacement: string) -> (),
	remove_range: (self: TransformContext, target: Syntax.Span) -> (),
	insert_before: (self: TransformContext, target: Syntax.SyntaxNode | Syntax.Span, source: string) -> (),
	insert_after: (self: TransformContext, target: Syntax.SyntaxNode | Syntax.Span, source: string) -> (),
	insert_import: (self: TransformContext, source: string) -> (),
	ensure_import: (self: TransformContext, binding: string, request: string) -> boolean,
}

--[=[
	@within Transform

	Describes a source transform and when it runs.
]=]
export type TransformDefinition = {
	phase: TransformPhase?,
	scope: Scope.Scope?,
	run: (tree: Query.SyntaxRoot, context: TransformContext) -> (),
}

--[=[
	@within Transform

	A validated transform that can be placed in a component or project.
]=]
export type TransformRule = {
	kind: "transform",
	name: string,
	phase: TransformPhase,
	scope: Scope.Scope?,
	run: (tree: Query.SyntaxRoot, context: TransformContext) -> (),
}

local transform = {}

--[=[
	@within Transform

	Creates a named source transform.

	@param name A unique transform name
	@param definition The callback, phase, and optional scope
	@return The validated transform
]=]
function transform.new(name: string, definition: TransformDefinition): TransformRule
	return nil :: any
end

return transform
