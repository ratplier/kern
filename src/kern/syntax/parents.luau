--!strict

const types = require("@kern/syntax/types")

export type ParentMap = {
	[any]: any,
}

local parents = {}

const function visit_node(
	node: any,
	parent: types.SyntaxNode?,
	parent_map: ParentMap,
	visited: { [types.SyntaxNode]: boolean }
)
	if typeof(node) ~= "table" or visited[node] then
		return
	end

	visited[node] = true

	const is_ast_node = node.tag ~= nil and node.location ~= nil

	if is_ast_node and parent ~= nil then
		-- TODO(luau): large Lute AST union.
		parent_map[node] = parent
	end

	const next_parent = if is_ast_node then node else parent

	for _, value in node do
		if typeof(value) == "table" then
			visit_node(value, next_parent, parent_map, visited)
		end
	end
end

function parents.build(tree: types.SyntaxTree): ParentMap
	const parent_map: ParentMap = {}
	const visited = {}

	visit_node(tree.root, nil, parent_map, visited)
	return parent_map
end

function parents.get(parent_map: ParentMap, node: types.SyntaxNode): types.SyntaxNode?
	return parent_map[node]
end

return parents
