--!strict

const common = require("@kern/query/builtins/common")
const query_types = require("@kern/query/types")

export type ModuleInfo = {
	kind: "require" | "return",
	require_path: string?,
	return_value_count: number?,
	is_supported_require: boolean?,
	is_aliased: boolean?,
	alias: string?,
	argument_span: query_types.Span?,
	span: query_types.Span,
	raw: any,
}

local modules = {}
local require_path_queries: { [string]: query_types.Query<ModuleInfo> } = {}

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

const function string_value(value: any): string?
	const text = token_text(value)
	if text == nil or #text < 2 then
		return text
	end
	const first = text:sub(1, 1)
	const last = text:sub(-1)
	if (first == '"' and last == '"') or (first == "'" and last == "'") then
		return text:sub(2, -2)
	end
	return text
end

const function normalize_require(node: any): ModuleInfo
	const argument_item = node.arguments[1]
	const argument = if argument_item ~= nil then argument_item.node or argument_item else nil
	const is_string = argument ~= nil and argument.tag == "string"
	const require_path = if is_string then string_value(argument.value or argument.token) else nil
	const alias = if require_path ~= nil then require_path:match("^(@[^/]+)") else nil
	return {
		kind = "require",
		require_path = require_path,
		return_value_count = nil,
		is_supported_require = is_string and #node.arguments == 1,
		is_aliased = alias ~= nil,
		alias = alias,
		argument_span = if argument ~= nil then argument.location else nil,
		span = node.location,
		raw = node,
	}
end

const function normalize_return(node: any): ModuleInfo
	return {
		kind = "return",
		require_path = nil,
		return_value_count = #node.expressions,
		is_supported_require = nil,
		is_aliased = nil,
		alias = nil,
		argument_span = nil,
		span = node.location,
		raw = node,
	}
end

const requires = common.tag("call", normalize_require):where(function(value: ModuleInfo): boolean
	return value.raw.func ~= nil and value.raw.func.tag == "global" and token_text(value.raw.func.name) == "require"
end)
modules.requires = requires
modules.returns = common.tag("return", normalize_return)
modules.aliased_requires = requires:where(function(value: ModuleInfo): boolean
	return value.is_aliased == true
end)
modules.relative_requires = requires:where(function(value: ModuleInfo): boolean
	return value.is_aliased == false
end)
modules.unsupported_requires = requires:where(function(value: ModuleInfo): boolean
	return value.is_supported_require == false
end)
modules.empty_returns = modules.returns:where(function(value: ModuleInfo): boolean
	return value.return_value_count == 0
end)

function modules.require_path(pattern: string): query_types.Query<ModuleInfo>
	if require_path_queries[pattern] ~= nil then
		return require_path_queries[pattern]
	end
	const value = requires:where(function(value: ModuleInfo): boolean
		return value.require_path ~= nil and value.require_path:match(pattern) ~= nil
	end)
	require_path_queries[pattern] = value
	return value
end

function modules.require_path_equal_to(expected: string): query_types.Query<ModuleInfo>
	return requires:where(function(value: ModuleInfo): boolean
		return value.require_path == expected
	end)
end

function modules.require_alias(alias: string): query_types.Query<ModuleInfo>
	return requires:where(function(value: ModuleInfo): boolean
		return value.alias == alias
	end)
end

function modules.with_return_value_count(count: number): query_types.Query<ModuleInfo>
	return modules.returns:where(function(value: ModuleInfo): boolean
		return value.return_value_count == count
	end)
end

return modules
