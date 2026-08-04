--!strict

export type Cache = {
	[any]: { [any]: { any } },
}

local cache = {}

function cache.new(): Cache
	return {}
end

function cache.get<Result>(cache_table: Cache, query: any, root: any): { Result }?
	const query_cache = cache_table[query]
	if query_cache == nil then
		return nil
	end

	-- TODO(luau): erased generic value type behind identity keys.
	return query_cache[root] :: { Result }?
end

function cache.set<Result>(cache_table: Cache, query: any, root: any, values: { Result })
	local query_cache = cache_table[query]
	if query_cache == nil then
		query_cache = {}
		cache_table[query] = query_cache
	end

	query_cache[root] = values
end

return cache
