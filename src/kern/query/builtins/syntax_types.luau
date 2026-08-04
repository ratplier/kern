--!strict

const common = require("@kern/query/builtins/common")
const query_types = require("@kern/query/types")

export type TypeInfo = {
	kind: string,
	name: string?,
	is_export: boolean,
	span: query_types.Span,
	raw: any,
}

local types = {}
local reference_queries: { [string]: query_types.Query<TypeInfo> } = {}
local union_queries: { [string]: query_types.Query<TypeInfo> } = {}
local alias_queries: { [string]: query_types.Query<TypeInfo> } = {}

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

const function normalize(node: any): TypeInfo
	return {
		kind = node.tag,
		name = token_text(node.name),
		is_export = node.isExport == true or node.export ~= nil,
		span = node.location,
		raw = node,
	}
end

const any_query = common.any(normalize)
types.any = any_query
types.annotations = any_query:where(function(value: TypeInfo): boolean
	return value.raw.kind == "type" or value.kind == "annotation"
end)
types.optional = any_query:where(function(value: TypeInfo): boolean
	return value.kind == "optional"
end)
types.unannotated_parameter = any_query:where(function(value: TypeInfo): boolean
	if value.raw.tag ~= "function" then
		return false
	end
	for _, parameter in value.raw.parameters or {} do
		if parameter.annotation == nil then
			return true
		end
	end
	return false
end)
types.unannotated_return = any_query:where(function(value: TypeInfo): boolean
	if value.raw.tag == "function" then
		return value.raw.returnAnnotation == nil
	end
	if value.raw.tag == "localfunction" then
		return value.raw.func.returnAnnotation == nil
	end
	return false
end)
function types.reference(name: string): query_types.Query<TypeInfo>
	if reference_queries[name] ~= nil then
		return reference_queries[name]
	end
	const value = any_query:where(function(value: TypeInfo): boolean
		return value.kind == "reference" and value.name == name
	end)
	reference_queries[name] = value
	return value
end

function types.alias(name: string?): query_types.Query<TypeInfo>
	const key = name or ""
	if alias_queries[key] ~= nil then
		return alias_queries[key]
	end
	const value = any_query:where(function(value: TypeInfo): boolean
		return (value.kind == "typealias" or value.kind == "typefunction") and (name == nil or value.name == name)
	end)
	alias_queries[key] = value
	return value
end

function types.union_containing(name: string): query_types.Query<TypeInfo>
	if union_queries[name] ~= nil then
		return union_queries[name]
	end
	const value = any_query:where(function(value: TypeInfo): boolean
		if value.kind ~= "union" then
			return false
		end
		for _, item in value.raw.types or {} do
			const node = item.node or item
			if node.name ~= nil and token_text(node.name) == name then
				return true
			end
		end
		return false
	end)
	union_queries[name] = value
	return value
end

return types
