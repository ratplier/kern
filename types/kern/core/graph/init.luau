--!nocheck

const Syntax = require("@kern/syntax/types")

--[=[
	@within Graph

	A resolved dependency between two modules.
]=]
export type ModuleEdge = {
	request: string,
	source_path: string,
	destination_path: string,
	span: Syntax.Span,
}

--[=[
	@within Graph

	One module and its relationships in a build graph.
]=]
export type ModuleNode = {
	source_path: string,
	output_path: string?,
	dependencies: { ModuleEdge },
	dependents: { ModuleEdge },
}

--[=[
	@within Graph

	The ordered dependency graph produced by a project build.
]=]
export type ModuleGraph = {
	entries: { string },
	nodes: { [string]: ModuleNode },
	ordered_paths: { string },
}

return {}
