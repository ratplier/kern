--!nocheck

const Types = require("@kern/query/types")

local query = {}

--[=[
	@within Query

	Creates a query from matchers and a normalizer.

	@param matchers Predicates that select syntax nodes
	@param normalize Converts a matching node into a result
	@return A reusable query
]=]
function query.new<Result>(matchers: { Types.Matcher }, normalize: Types.Normalizer<Result>): Types.Query<Result>
	return nil :: any
end

--[=[
	@within Query

	Creates a query backed by a custom evaluator.

	@param evaluator Produces results from a syntax root
	@return A reusable query
]=]
function query.from_evaluator<Result>(evaluator: (root: Types.SyntaxRoot) -> { Result }): Types.Query<Result>
	return nil :: any
end

--[=[
	@within Query

	Syntax-node matchers used to construct queries. Use `where` to add a custom
	predicate to any existing matcher.
]=]
query.match = nil :: {
	stat_function: Types.Matcher,
	local_function: Types.Matcher,
	expression_function: Types.Matcher,
	any_function: Types.Matcher,
	any_call: Types.Matcher,
	any_assignment: Types.Matcher,
	any_local: Types.Matcher,
	any_loop: Types.Matcher,
	any_if: Types.Matcher,
	any_return: Types.Matcher,
	any_binary: Types.Matcher,
	any_unary: Types.Matcher,
	any_string: Types.Matcher,
	any_table: Types.Matcher,
	any_type: Types.Matcher,
	type_alias: Types.Matcher,
	type_function: Types.Matcher,
	where: (matcher: Types.Matcher, predicate: Types.Matcher) -> Types.Matcher,
}

--[=[
	@within Query

	Reusable predicates for narrowing query results.

	Top-level filters compose predicates and compare selected values. Specialized
	`string`, `number`, `array`, and `boolean` groups provide common predicates
	without requiring a new callback for each query.
]=]
query.filters = nil :: {
	all: <Result>(predicates: { Types.Filter<Result> }) -> Types.Filter<Result>,
	any: <Result>(predicates: { Types.Filter<Result> }) -> Types.Filter<Result>,
	none: <Result>(predicates: { Types.Filter<Result> }) -> Types.Filter<Result>,
	xor: <Result>(first: Types.Filter<Result>, second: Types.Filter<Result>) -> Types.Filter<Result>,
	not_: <Result>(predicate: Types.Filter<Result>) -> Types.Filter<Result>,
	always: <Result>() -> Types.Filter<Result>,
	never: <Result>() -> Types.Filter<Result>,
	equals: <Result>(expected: Result) -> Types.Filter<Result>,
	not_equals: <Result>(expected: Result) -> Types.Filter<Result>,
	one_of: <Result>(expected: { Result }) -> Types.Filter<Result>,
	not_one_of: <Result>(expected: { Result }) -> Types.Filter<Result>,
	is_nil: <Result>() -> Types.Filter<Result?>,
	is_present: <Result>() -> Types.Filter<Result?>,
	by: <Result, Selected>(selector: (Result) -> Selected, predicate: Types.Filter<Selected>) -> Types.Filter<Result>,
	equals_by: <Result, Selected>(selector: (Result) -> Selected?, expected: Selected) -> Types.Filter<Result>,
	one_of_by: <Result, Selected>(selector: (Result) -> Selected?, expected: { Selected }) -> Types.Filter<Result>,
	string: {
		equals: (expected: string, ignore_case: boolean?) -> Types.Filter<string>,
		contains: (needle: string, ignore_case: boolean?) -> Types.Filter<string>,
		starts_with: (prefix: string, ignore_case: boolean?) -> Types.Filter<string>,
		ends_with: (suffix: string, ignore_case: boolean?) -> Types.Filter<string>,
		matches: (pattern: string) -> Types.Filter<string>,
		empty: () -> Types.Filter<string>,
		non_empty: () -> Types.Filter<string>,
		has_length: (length: number) -> Types.Filter<string>,
		minimum_length: (minimum: number) -> Types.Filter<string>,
		maximum_length: (maximum: number) -> Types.Filter<string>,
		length_between: (minimum: number, maximum: number) -> Types.Filter<string>,
	},
	number: {
		greater_than: (minimum: number) -> Types.Filter<number>,
		at_least: (minimum: number) -> Types.Filter<number>,
		less_than: (maximum: number) -> Types.Filter<number>,
		at_most: (maximum: number) -> Types.Filter<number>,
		between: (minimum: number, maximum: number) -> Types.Filter<number>,
		outside: (minimum: number, maximum: number) -> Types.Filter<number>,
		positive: () -> Types.Filter<number>,
		negative: () -> Types.Filter<number>,
		zero: () -> Types.Filter<number>,
		integer: () -> Types.Filter<number>,
		finite: () -> Types.Filter<number>,
	},
	array: {
		empty: <Result>() -> Types.Filter<{ Result }>,
		non_empty: <Result>() -> Types.Filter<{ Result }>,
		has_length: <Result>(length: number) -> Types.Filter<{ Result }>,
		minimum_length: <Result>(minimum: number) -> Types.Filter<{ Result }>,
		maximum_length: <Result>(maximum: number) -> Types.Filter<{ Result }>,
		length_between: <Result>(minimum: number, maximum: number) -> Types.Filter<{ Result }>,
		contains: <Result>(expected: Result) -> Types.Filter<{ Result }>,
		any: <Result>(predicate: Types.Filter<Result>) -> Types.Filter<{ Result }>,
		all: <Result>(predicate: Types.Filter<Result>) -> Types.Filter<{ Result }>,
		none: <Result>(predicate: Types.Filter<Result>) -> Types.Filter<{ Result }>,
	},
	boolean: {
		is_true: () -> Types.Filter<boolean>,
		is_false: () -> Types.Filter<boolean>,
	},
}

return query
