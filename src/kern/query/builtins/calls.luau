--!strict

const query = require("@kern/query")
const query_types = require("@kern/query/types")

export type CallInfo = {
	callee: string?,
	is_global: boolean,
	is_method: boolean,
	argument_count: number,
	arguments: { any },
	function_depth: number,
	block_depth: number,
	is_top_level: boolean,
	span: query_types.Span,
	callee_span: query_types.Span?,
	callee_node: query_types.SyntaxExpression?,
	raw: any,
}

local calls = {}
local global_queries: { [string]: query_types.Query<CallInfo> } = {}
local method_queries: { [string]: query_types.Query<CallInfo> } = {}
local member_queries: { [string]: query_types.Query<CallInfo> } = {}
local argument_count_queries: { [number]: query_types.Query<CallInfo> } = {}
local minimum_argument_queries: { [number]: query_types.Query<CallInfo> } = {}

const function normalize(node: any, function_depth: number, block_depth: number): CallInfo
	const func = node.func
	const is_global = func ~= nil and func.tag == "global"
	const is_method = node.self == true
	local callee: string? = nil
	if is_global and func.name ~= nil then
		-- TODO(luau): missing Lute named-function token type.
		const name_token = func.name :: { text: string }
		callee = name_token.text
	elseif func ~= nil and func.tag == "indexname" and func.index ~= nil then
		-- TODO(luau): unnarrowed Lute index-node union.
		const index_token = func.index :: any
		callee = if index_token.text ~= nil then tostring(index_token.text) else tostring(index_token)
	end

	return {
		callee = callee,
		is_global = is_global,
		is_method = is_method,
		argument_count = #node.arguments,
		arguments = node.arguments,
		function_depth = function_depth,
		block_depth = block_depth,
		is_top_level = function_depth == 0 and block_depth == 0,
		span = node.location,
		callee_span = if func ~= nil then func.location else nil,
		callee_node = func,
		raw = node,
	}
end

const function is_block(node: any): boolean
	return node.tag == "block"
		or node.tag == "conditional"
		or node.tag == "while"
		or node.tag == "repeat"
		or node.tag == "for"
		or node.tag == "forin"
end

const function is_function(node: any): boolean
	return node.tag == "function" or node.tag == "localfunction"
end

const function collect_calls(root: query_types.SyntaxRoot): { CallInfo }
	const values = {}

	const function visit(node: any, function_depth: number, block_depth: number)
		if typeof(node) ~= "table" then
			return
		end

		if node.tag == "call" then
			table.insert(values, normalize(node, function_depth, block_depth))
		end

		const next_function_depth = if is_function(node) then function_depth + 1 else function_depth
		const next_block_depth = if is_block(node) then block_depth + 1 else block_depth
		for _, child in node do
			if typeof(child) == "table" then
				visit(child, next_function_depth, next_block_depth)
			end
		end
	end

	visit(root, 0, 0)
	return values
end

const any_query = query.from_evaluator(collect_calls)
calls.any = any_query

function calls.global(name: string): query_types.Query<CallInfo>
	if global_queries[name] ~= nil then
		return global_queries[name]
	end
	const value = any_query:where(function(value: CallInfo): boolean
		return value.is_global and value.callee == name
	end)
	global_queries[name] = value
	return value
end

function calls.method(name: string?): query_types.Query<CallInfo>
	const key = name or ""
	if method_queries[key] ~= nil then
		return method_queries[key]
	end
	const value = any_query:where(function(value: CallInfo): boolean
		return value.is_method and (name == nil or value.callee == name)
	end)
	method_queries[key] = value
	return value
end

function calls.member(name: string?): query_types.Query<CallInfo>
	const key = name or ""
	if member_queries[key] ~= nil then
		return member_queries[key]
	end
	const value = any_query:where(function(value: CallInfo): boolean
		return not value.is_global and (name == nil or value.callee == name)
	end)
	member_queries[key] = value
	return value
end

function calls.with_argument_count(count: number): query_types.Query<CallInfo>
	if argument_count_queries[count] ~= nil then
		return argument_count_queries[count]
	end
	const value = any_query:where(function(value: CallInfo): boolean
		return value.argument_count == count
	end)
	argument_count_queries[count] = value
	return value
end

function calls.with_minimum_arguments(minimum: number): query_types.Query<CallInfo>
	if minimum_argument_queries[minimum] ~= nil then
		return minimum_argument_queries[minimum]
	end
	const value = any_query:where(function(value: CallInfo): boolean
		return value.argument_count >= minimum
	end)
	minimum_argument_queries[minimum] = value
	return value
end

calls.no_arguments = calls.with_argument_count(0)
calls.top_level = any_query:where(function(value: CallInfo): boolean
	return value.is_top_level
end)
calls.nested = any_query:where(function(value: CallInfo): boolean
	return not value.is_top_level
end)
calls.inside_function = any_query:where(function(value: CallInfo): boolean
	return value.function_depth > 0
end)

function calls.with_maximum_arguments(maximum: number): query_types.Query<CallInfo>
	return any_query:where(function(value: CallInfo): boolean
		return value.argument_count <= maximum
	end)
end

function calls.argument_count_between(minimum: number, maximum: number): query_types.Query<CallInfo>
	return any_query:where(function(value: CallInfo): boolean
		return value.argument_count >= minimum and value.argument_count <= maximum
	end)
end

return calls
