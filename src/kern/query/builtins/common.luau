--!strict

const query = require("@kern/query")
const query_types = require("@kern/query/types")

local common = {}

function common.tag<Result>(tag: string, normalize: (node: query_types.SyntaxNode) -> Result): query_types.Query<Result>
	return query.new({
		function(node: query_types.SyntaxNode): boolean
			if node.kind ~= "expr" and node.kind ~= "stat" then
				return false
			end
			return node.tag == tag
		end,
	}, normalize)
end

function common.any<Result>(normalize: (node: query_types.SyntaxNode) -> Result): query_types.Query<Result>
	return query.new({
		function(_node: query_types.SyntaxNode): boolean
			return true
		end,
	}, normalize)
end

return common
