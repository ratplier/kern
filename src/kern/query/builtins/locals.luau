--!strict

const common = require("@kern/query/builtins/common")
const query_types = require("@kern/query/types")

export type LocalInfo = {
	name: string,
	has_annotation: boolean,
	has_value: boolean,
	is_const: boolean,
	annotation_name: string?,
	span: query_types.Span,
	raw: any,
}

local locals = {}
local named_queries: { [string]: query_types.Query<LocalInfo> } = {}
local annotation_queries: { [string]: query_types.Query<LocalInfo> } = {}

const function token_text(value: any): string?
	if value == nil then
		return nil
	end
	if value.text ~= nil then
		return tostring(value.text)
	end
	return tostring(value)
end

const function normalize(node: any): LocalInfo
	const names = node.variables or node.localNames or {}
	const first_variable = names[1]
	const first_name = if first_variable ~= nil then first_variable.node else nil
	-- TODO(luau): untyped Lute local-name field.
	const first_name_value = first_name :: any
	const annotation = if first_name ~= nil then first_name_value.annotation else nil
	-- TODO(luau): unnarrowed Lute annotation node.
	const annotation_value = annotation :: any

	return {
		name = if first_name ~= nil then token_text(first_name_value.name) or "" else "",
		has_annotation = annotation ~= nil,
		has_value = node.values ~= nil and #node.values > 0,
		is_const = node.localKeyword ~= nil and tostring(node.localKeyword) == "const",
		annotation_name = if annotation ~= nil then token_text(annotation_value.name) else nil,
		span = node.location,
		raw = node,
	}
end

const any = common.tag("local", normalize)
locals.any = any
const uninitialized_query = any:where(function(value: LocalInfo): boolean
	return not value.has_value
end)

locals.uninitialized = uninitialized_query
locals.initialized = any:where(function(value: LocalInfo): boolean
	return value.has_value
end)
locals.annotated = any:where(function(value: LocalInfo): boolean
	return value.has_annotation
end)
locals.unannotated = any:where(function(value: LocalInfo): boolean
	return not value.has_annotation
end)
locals.constant = any:where(function(value: LocalInfo): boolean
	return value.is_const
end)
locals.mutable = any:where(function(value: LocalInfo): boolean
	return not value.is_const
end)

function locals.named(name: string): query_types.Query<LocalInfo>
	if named_queries[name] ~= nil then
		return named_queries[name]
	end
	const value = any:where(function(value: LocalInfo): boolean
		return value.name == name
	end)
	named_queries[name] = value
	return value
end

function locals.annotated_with(type_name: string): query_types.Query<LocalInfo>
	if annotation_queries[type_name] ~= nil then
		return annotation_queries[type_name]
	end
	const value = any:where(function(value: LocalInfo): boolean
		return value.annotation_name == type_name
	end)
	annotation_queries[type_name] = value
	return value
end

return locals
