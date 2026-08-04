--!strict

const common = require("@kern/query/builtins/common")
const query_types = require("@kern/query/types")

export type TableInfo = {
	entry_count: number,
	has_record_entries: boolean,
	has_array_entries: boolean,
	is_empty: boolean,
	span: query_types.Span,
	raw: any,
}

local tables = {}
local key_queries: { [string]: query_types.Query<TableInfo> } = {}
local minimum_entry_queries: { [number]: query_types.Query<TableInfo> } = {}

const function normalize(node: any): TableInfo
	const entries = node.entries or {}
	local has_record_entries = false
	local has_array_entries = false

	for _, entry in entries do
		if entry.key ~= nil then
			has_record_entries = true
		else
			has_array_entries = true
		end
	end

	return {
		entry_count = #entries,
		has_record_entries = has_record_entries,
		has_array_entries = has_array_entries,
		is_empty = #entries == 0,
		span = node.location,
		raw = node,
	}
end

const any_query = common.tag("table", normalize)
tables.any = any_query
const empty_query = any_query:where(function(value: TableInfo): boolean
	return value.is_empty
end)
const array_query = any_query:where(function(value: TableInfo): boolean
	return value.has_array_entries
end)
const record_query = any_query:where(function(value: TableInfo): boolean
	return value.has_record_entries
end)

tables.empty = empty_query
tables.array_style = array_query
tables.record_style = record_query
tables.mixed = any_query:where(function(value: TableInfo): boolean
	return value.has_array_entries and value.has_record_entries
end)

function tables.with_key(name: string): query_types.Query<TableInfo>
	if key_queries[name] ~= nil then
		return key_queries[name]
	end
	const value = any_query:where(function(value: TableInfo): boolean
		for _, entry in value.raw.entries or {} do
			const key = entry.key
			const key_name = if key ~= nil and key.text ~= nil then tostring(key.text) else nil
			const key_value = if key ~= nil and key.value ~= nil then tostring(key.value) else nil
			if key ~= nil and (key_name == name or key_value == name) then
				return true
			end
		end
		return false
	end)
	key_queries[name] = value
	return value
end

function tables.with_minimum_entries(minimum: number): query_types.Query<TableInfo>
	if minimum_entry_queries[minimum] ~= nil then
		return minimum_entry_queries[minimum]
	end
	const value = any_query:where(function(value: TableInfo): boolean
		return value.entry_count >= minimum
	end)
	minimum_entry_queries[minimum] = value
	return value
end

function tables.with_maximum_entries(maximum: number): query_types.Query<TableInfo>
	return any_query:where(function(value: TableInfo): boolean
		return value.entry_count <= maximum
	end)
end

function tables.with_entry_count(count: number): query_types.Query<TableInfo>
	return any_query:where(function(value: TableInfo): boolean
		return value.entry_count == count
	end)
end

function tables.entry_count_between(minimum: number, maximum: number): query_types.Query<TableInfo>
	return any_query:where(function(value: TableInfo): boolean
		return value.entry_count >= minimum and value.entry_count <= maximum
	end)
end

return tables
