--!strict

const common = require("@kern/query/builtins/common")
const query_types = require("@kern/query/types")

export type FunctionParameter = {
	name: string?,
	raw: any,
}

export type FunctionInfo = {
	name: string?,
	is_local: boolean,
	is_method: boolean,
	parameter_count: number,
	parameters: { FunctionParameter },
	has_return_type: boolean,
	has_variadic_parameter: boolean,
	body_statement_count: number,
	span: query_types.Span,
	raw: any,
}

local functions = {}
local named_queries: { [string]: query_types.Query<FunctionInfo> } = {}
local parameter_count_queries: { [number]: query_types.Query<FunctionInfo> } = {}
local minimum_parameter_queries: { [number]: query_types.Query<FunctionInfo> } = {}
local attribute_queries: { [string]: query_types.Query<FunctionInfo> } = {}
local returning_queries: { [string]: query_types.Query<FunctionInfo> } = {}

const function token_text(value: any): string?
	if value == nil then
		return nil
	end
	if value.text ~= nil then
		return tostring(value.text)
	end
	return tostring(value)
end

const function function_name(node: any): string?
	if node.name == nil then
		return nil
	end
	if node.name.name ~= nil then
		return token_text(node.name.name)
	end
	if node.name.index ~= nil then
		return token_text(node.name.index)
	end
	if node.name.tag == "global" then
		return token_text(node.name.name)
	end
	return token_text(node.name)
end

const function annotation_name(value: any): string?
	if value == nil then
		return nil
	end
	-- TODO(luau): unnarrowed Lute function node value.
	const raw_value = value :: any
	if raw_value.name ~= nil then
		return token_text(raw_value.name)
	end
	const type_values = raw_value.types
	if type_values == nil or type_values[1] == nil then
		return nil
	end
	if type_values[1] ~= nil then
		const first_type = type_values[1].node or type_values[1]
		return token_text(first_type.name)
	end
	return nil
end

const function contains_text(value: any, expected: string): boolean
	if typeof(value) ~= "table" then
		return false
	end
	if value.text ~= nil and tostring(value.text) == expected then
		return true
	end
	for _, child in value do
		if typeof(child) == "table" and contains_text(child, expected) then
			return true
		end
	end
	return false
end

const function normalize(node: any): FunctionInfo
	const function_node = if node.tag == "function" and node.func ~= nil then node.func else node
	const parameters = function_node.parameters or {}
	const body = function_node.body
	const parameter_info = {}

	for _, parameter in parameters do
		table.insert(parameter_info, {
			name = if parameter.name ~= nil then tostring(parameter.name) else nil,
			raw = parameter,
		})
	end

	return {
		name = function_name(node),
		is_local = node.tag == "localfunction",
		is_method = node.name ~= nil and node.name.tag == "indexname" and node.name.accessor ~= nil and tostring(
			node.name.accessor
		) == ":",
		parameter_count = #parameter_info,
		parameters = parameter_info,
		has_return_type = function_node.returnAnnotation ~= nil,
		has_variadic_parameter = function_node.vararg ~= nil,
		body_statement_count = if body ~= nil then #body.statements else 0,
		span = node.location,
		raw = node,
	}
end

const any_query = common.any(normalize):where(function(value: FunctionInfo): boolean
	return value.raw.tag == "function" or value.raw.tag == "localfunction"
end)
const local_function = any_query:where(function(value: FunctionInfo): boolean
	return value.is_local
end)
const anonymous_query = any_query:where(function(value: FunctionInfo): boolean
	return value.name == nil
end)
const variadic_query = any_query:where(function(value: FunctionInfo): boolean
	return value.has_variadic_parameter
end)
const untyped_query = any_query:where(function(value: FunctionInfo): boolean
	return not value.has_return_type
end)
functions.any = any_query
functions.local_function = local_function
functions.anonymous = anonymous_query
functions.variadic = variadic_query
functions.untyped = untyped_query
functions.no_parameters = any_query:where(function(value: FunctionInfo): boolean
	return value.parameter_count == 0
end)
functions.typed = any_query:where(function(value: FunctionInfo): boolean
	return value.has_return_type
end)
functions.empty_body = any_query:where(function(value: FunctionInfo): boolean
	return value.body_statement_count == 0
end)

function functions.named(name: string): query_types.Query<FunctionInfo>
	if named_queries[name] ~= nil then
		return named_queries[name]
	end
	const value = any_query:where(function(value: FunctionInfo): boolean
		return value.name == name
	end)
	named_queries[name] = value
	return value
end

function functions.with_parameter_count(count: number): query_types.Query<FunctionInfo>
	if parameter_count_queries[count] ~= nil then
		return parameter_count_queries[count]
	end
	const value = any_query:where(function(value: FunctionInfo): boolean
		return value.parameter_count == count
	end)
	parameter_count_queries[count] = value
	return value
end

function functions.with_minimum_parameters(minimum: number): query_types.Query<FunctionInfo>
	if minimum_parameter_queries[minimum] ~= nil then
		return minimum_parameter_queries[minimum]
	end
	const value = any_query:where(function(value: FunctionInfo): boolean
		return value.parameter_count >= minimum
	end)
	minimum_parameter_queries[minimum] = value
	return value
end

function functions.with_maximum_parameters(maximum: number): query_types.Query<FunctionInfo>
	return any_query:where(function(value: FunctionInfo): boolean
		return value.parameter_count <= maximum
	end)
end

function functions.parameter_count_between(minimum: number, maximum: number): query_types.Query<FunctionInfo>
	return any_query:where(function(value: FunctionInfo): boolean
		return value.parameter_count >= minimum and value.parameter_count <= maximum
	end)
end

function functions.with_attribute(attribute: string): query_types.Query<FunctionInfo>
	if attribute_queries[attribute] ~= nil then
		return attribute_queries[attribute]
	end
	const value = any_query:where(function(value: FunctionInfo): boolean
		for _, current in value.raw.attributes or {} do
			if token_text(current.name) == attribute or tostring(current) == attribute then
				return true
			end
		end
		return false
	end)
	attribute_queries[attribute] = value
	return value
end

function functions.returning(type_name: string): query_types.Query<FunctionInfo>
	if returning_queries[type_name] ~= nil then
		return returning_queries[type_name]
	end
	const value = any_query:where(function(value: FunctionInfo): boolean
		const annotation = value.raw.func ~= nil and value.raw.func.returnAnnotation or value.raw.returnAnnotation
		return annotation_name(annotation) == type_name
			or (value.has_return_type and contains_text(value.raw, type_name))
	end)
	returning_queries[type_name] = value
	return value
end

return functions
