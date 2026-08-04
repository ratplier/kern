--!strict

const common = require("@kern/query/builtins/common")
const query_types = require("@kern/query/types")

export type OperatorInfo = {
	operator: string,
	is_binary: boolean,
	is_unary: boolean,
	span: query_types.Span,
	raw: any,
}

local operators = {}
local binary_queries: { [string]: query_types.Query<OperatorInfo> } = {}
local unary_queries: { [string]: query_types.Query<OperatorInfo> } = {}

const function token_text(value: any): string?
	if value == nil then
		return nil
	end
	if typeof(value) ~= "table" then
		return tostring(value)
	end
	if value.text ~= nil then
		return tostring(value.text)
	end
	return tostring(value)
end

const function normalize(node: any): OperatorInfo
	const operator = token_text(node.operator) or ""
	return {
		operator = operator,
		is_binary = node.tag == "binary",
		is_unary = node.tag == "unary",
		span = node.location,
		raw = node,
	}
end

const binary = common.tag("binary", normalize)
const unary = common.tag("unary", normalize)
operators.any_binary = binary
operators.any_unary = unary
operators.and_or_ternary = binary:where(function(value: OperatorInfo): boolean
	return value.operator == "and" or value.operator == "or"
end)

function operators.binary(operator: string?): query_types.Query<OperatorInfo>
	const key = operator or ""
	if binary_queries[key] ~= nil then
		return binary_queries[key]
	end
	const value = binary:where(function(value: OperatorInfo): boolean
		return operator == nil or value.operator == operator
	end)
	binary_queries[key] = value
	return value
end

function operators.unary(operator: string?): query_types.Query<OperatorInfo>
	const key = operator or ""
	if unary_queries[key] ~= nil then
		return unary_queries[key]
	end
	const value = unary:where(function(value: OperatorInfo): boolean
		return operator == nil or value.operator == operator
	end)
	unary_queries[key] = value
	return value
end

return operators
