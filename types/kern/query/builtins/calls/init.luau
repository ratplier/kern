--!nocheck

const QueryTypes = require("@kern/query/types")

--[=[
	@within Calls

	A half-open byte range in Luau source.
]=]
export type Span = {
	start: number,
	finish: number,
}

--[=[
	@within Calls

	Normalized information about a function or method call.
]=]
export type CallInfo = {
	callee: string?,
	is_global: boolean,
	is_method: boolean,
	argument_count: number,
	arguments: { QueryTypes.SyntaxExpression },
	function_depth: number,
	block_depth: number,
	is_top_level: boolean,
	span: Span,
	callee_span: Span?,
	callee_node: QueryTypes.SyntaxExpression?,
	raw: QueryTypes.SyntaxExpression,
}

--[=[
	@within Calls

	A reusable query that visits, collects, or filters syntax matches.
]=]
export type Query<Result> = {
	visit: (self: Query<Result>, root: QueryTypes.SyntaxRoot) -> () -> Result?,
	each: (self: Query<Result>, root: QueryTypes.SyntaxRoot, callback: (value: Result) -> ()) -> (),
	collect: (self: Query<Result>, root: QueryTypes.SyntaxRoot) -> { Result },
	where: (self: Query<Result>, predicate: (value: Result) -> boolean) -> Query<Result>,
	filter: (self: Query<Result>, predicate: (value: Result) -> boolean) -> Query<Result>,
	where_all: (self: Query<Result>, predicates: { (value: Result) -> boolean }) -> Query<Result>,
	where_any: (self: Query<Result>, predicates: { (value: Result) -> boolean }) -> Query<Result>,
	where_none: (self: Query<Result>, predicates: { (value: Result) -> boolean }) -> Query<Result>,
	where_not: (self: Query<Result>, predicate: (value: Result) -> boolean) -> Query<Result>,
}

local calls = {}

--[=[
	@within Calls

	Matches every function and method call.
]=]
calls.any = nil :: Query<CallInfo>
calls.no_arguments = nil :: Query<CallInfo>
calls.top_level = nil :: Query<CallInfo>
calls.nested = nil :: Query<CallInfo>
calls.inside_function = nil :: Query<CallInfo>

--[=[
	@within Calls

	Matches calls to a global function with the given name.

	@param name The global function name
	@return A cached call query
]=]
function calls.global(name: string): Query<CallInfo>
	return nil :: any
end

--[=[
	@within Calls

	Matches method calls, optionally restricted to a method name.

	@param name An optional method name
	@return A cached call query
]=]
function calls.method(name: string?): Query<CallInfo>
	return nil :: any
end

--[=[
	@within Calls

	Matches non-global member calls, optionally restricted to a member name.

	@param name An optional member name
	@return A cached call query
]=]
function calls.member(name: string?): Query<CallInfo>
	return nil :: any
end

--[=[
	@within Calls

	Matches calls with exactly `count` arguments.

	@param count The required argument count
	@return A cached call query
]=]
function calls.with_argument_count(count: number): Query<CallInfo>
	return nil :: any
end

--[=[
	@within Calls

	Matches calls with at least `minimum` arguments.

	@param minimum The minimum argument count
	@return A cached call query
]=]
function calls.with_minimum_arguments(minimum: number): Query<CallInfo>
	return nil :: any
end

--[=[
	@within Calls

	Matches calls with at most `maximum` arguments.

	@param maximum The maximum argument count
	@return A reusable call query
]=]
function calls.with_maximum_arguments(maximum: number): Query<CallInfo>
	return nil :: any
end

--[=[
	@within Calls

	Matches calls whose argument count is within an inclusive range.

	@param minimum The inclusive minimum argument count
	@param maximum The inclusive maximum argument count
	@return A reusable call query
]=]
function calls.argument_count_between(minimum: number, maximum: number): Query<CallInfo>
	return nil :: any
end

return calls
