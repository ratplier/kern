--!nocheck

const Query = require("@kern/query/types")

local compose = {}

--[=[
	@within Query

	Matches values produced by either query, without duplicates.

	@param first The first query
	@param second The second query
	@return The combined query
]=]
function compose.union<Result>(first: Query.Query<Result>, second: Query.Query<Result>): Query.Query<Result>
	return nil :: any
end

--[=[
	@within Query

	Matches only values produced by both queries.

	@param first The first query
	@param second The second query
	@return The intersected query
]=]
function compose.intersect<Result>(first: Query.Query<Result>, second: Query.Query<Result>): Query.Query<Result>
	return nil :: any
end

--[=[
	@within Query

	Evaluates a child query after the parent query has matched.

	@param parent The outer query
	@param child The query evaluated after the parent
	@return The piped child query
]=]
function compose.pipe<Parent, Child>(parent: Query.Query<Parent>, child: Query.Query<Child>): Query.Query<Child>
	return nil :: any
end

return compose
