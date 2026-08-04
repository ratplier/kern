--!strict

const common = require("@kern/query/builtins/common")
const query_types = require("@kern/query/types")

export type StringInfo = {
	value: string?,
	is_interpolated: boolean,
	is_long_string: boolean,
	span: query_types.Span,
	raw: any,
}

local strings = {}
local matching_queries: { [string]: query_types.Query<StringInfo> } = {}

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

const function normalize(node: any): StringInfo
	return {
		value = token_text(node.value or node.token),
		is_interpolated = node.tag == "interpolatedstring",
		is_long_string = node.quoteStyle == "block",
		span = node.location,
		raw = node,
	}
end

const any_query = common.any(normalize):where(function(value: StringInfo): boolean
	return value.raw.tag == "string" or value.raw.tag == "interpolatedstring"
end)
strings.any = any_query
strings.plain = any_query:where(function(value: StringInfo): boolean
	return not value.is_interpolated
end)
strings.interpolated = any_query:where(function(value: StringInfo): boolean
	return value.is_interpolated
end)
strings.concatenated = common.tag("binary", normalize):where(function(value: StringInfo): boolean
	return value.raw.operator ~= nil and token_text(value.raw.operator) == ".."
end)
strings.empty = any_query:where(function(value: StringInfo): boolean
	return value.value == ""
end)
strings.non_empty = any_query:where(function(value: StringInfo): boolean
	return value.value ~= nil and value.value ~= ""
end)
strings.long = any_query:where(function(value: StringInfo): boolean
	return value.is_long_string
end)

function strings.matching(pattern: string): query_types.Query<StringInfo>
	if matching_queries[pattern] ~= nil then
		return matching_queries[pattern]
	end
	const value = strings.any:where(function(value: StringInfo): boolean
		return value.value ~= nil and value.value:match(pattern) ~= nil
	end)
	matching_queries[pattern] = value
	return value
end

function strings.equal_to(expected: string): query_types.Query<StringInfo>
	return any_query:where(function(value: StringInfo): boolean
		return value.value == expected
	end)
end

function strings.containing(expected: string): query_types.Query<StringInfo>
	return any_query:where(function(value: StringInfo): boolean
		return value.value ~= nil and value.value:find(expected, 1, true) ~= nil
	end)
end

function strings.starting_with(prefix: string): query_types.Query<StringInfo>
	return any_query:where(function(value: StringInfo): boolean
		return value.value ~= nil and value.value:sub(1, #prefix) == prefix
	end)
end

function strings.ending_with(suffix: string): query_types.Query<StringInfo>
	return any_query:where(function(value: StringInfo): boolean
		return value.value ~= nil and (suffix == "" or value.value:sub(-#suffix) == suffix)
	end)
end

function strings.with_minimum_length(minimum: number): query_types.Query<StringInfo>
	return any_query:where(function(value: StringInfo): boolean
		return value.value ~= nil and #value.value >= minimum
	end)
end

function strings.with_maximum_length(maximum: number): query_types.Query<StringInfo>
	return any_query:where(function(value: StringInfo): boolean
		return value.value ~= nil and #value.value <= maximum
	end)
end

return strings
