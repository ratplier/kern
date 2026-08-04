--!strict

const query = require("@kern/query")
const query_types = require("@kern/query/types")

local compose = {}

function compose.union<Result>(first: query_types.Query<Result>, second: query_types.Query<Result>): query_types.Query<Result>
	return query.from_evaluator(function(root: query_types.SyntaxRoot): { Result }
		const values = {}
		const seen = {}

		for _, source_query in { first, second } do
			for _, value in source_query:collect(root) do
				const key = if typeof(value) == "table" and value.raw ~= nil then value.raw else value
				if not seen[key] then
					seen[key] = true
					table.insert(values, value)
				end
			end
		end

		return values
	end)
end

function compose.intersect<Result>(
	first: query_types.Query<Result>,
	second: query_types.Query<Result>
): query_types.Query<Result>
	return query.from_evaluator(function(root: query_types.SyntaxRoot): { Result }
		const second_values = second:collect(root)
		const second_nodes = {}
		const values = {}

		for _, value in second_values do
			const key = if typeof(value) == "table" and value.raw ~= nil then value.raw else value
			second_nodes[key] = true
		end

		for _, value in first:collect(root) do
			const key = if typeof(value) == "table" and value.raw ~= nil then value.raw else value
			if second_nodes[key] then
				table.insert(values, value)
			end
		end

		return values
	end)
end

function compose.pipe<Parent, Child>(parent: query_types.Query<Parent>, child: query_types.Query<Child>): query_types.Query<Child>
	return query.from_evaluator(function(root: query_types.SyntaxRoot): { Child }
		const values = {}

		for _, parent_value in parent:collect(root) do
			if typeof(parent_value) == "table" and parent_value.raw ~= nil then
				-- TODO(luau): raw node inside normalized query value.
				const child_values = child:collect(parent_value.raw :: query_types.SyntaxRoot)
				for _, child_value in child_values do
					table.insert(values, child_value)
				end
			end
		end

		return values
	end)
end

return compose
