--!strict

const cache = require("@kern/query/cache")
const query_types = require("@kern/query/types")

type Evaluator<Result> = (root: query_types.SyntaxRoot) -> { Result }

local query = {}

local match = {}

type NodeFields = { [string]: unknown }

const function field(node: query_types.SyntaxNode, name: string): unknown
	-- TODO(luau): variant Lute fields across AST nodes.
	const fields = node :: NodeFields
	return fields[name]
end

const function walk(node: query_types.SyntaxNode, callback: (query_types.SyntaxNode) -> ())
	if field(node, "tag") ~= nil and field(node, "location") ~= nil then
		callback(node)
	end

	for _, value in node do
		if typeof(value) == "table" then
			-- TODO(luau): unnarrowed recursive Lute child value.
			walk(value :: query_types.SyntaxNode, callback)
		end
	end
end

const function create_query<Result>(evaluator: Evaluator<Result>): query_types.Query<Result>
	local query_object = {}
	const query_cache = cache.new()

	function query_object.visit(self: query_types.Query<Result>, root: query_types.SyntaxRoot): () -> Result?
		const values = self:collect(root)
		local index = 0

		return function(): Result?
			index += 1
			return values[index]
		end
	end

	function query_object.each(self: query_types.Query<Result>, root: query_types.SyntaxRoot, callback: (Result) -> ())
		for value in self:visit(root) do
			if value ~= nil then
				callback(value)
			end
		end
	end

	function query_object.collect(self: query_types.Query<Result>, root: query_types.SyntaxRoot): { Result }
		-- TODO(luau): erased generic result type in cache.
		const cached = cache.get(query_cache, self, root) :: { Result }?
		if cached ~= nil then
			return cached
		end

		const values = evaluator(root)
		cache.set(query_cache, self, root, values)
		return values
	end

	function query_object.where(
		self: query_types.Query<Result>,
		predicate: (Result) -> boolean
	): query_types.Query<Result>
		return create_query(function(root: query_types.SyntaxRoot): { Result }
			const values = {}

			for _, value in self:collect(root) do
				if predicate(value) then
					table.insert(values, value)
				end
			end

			return values
		end)
	end

	query_object.filter = query_object.where

	function query_object.where_all(
		self: query_types.Query<Result>,
		predicates: { query_types.Filter<Result> }
	): query_types.Query<Result>
		return self:where(function(value: Result): boolean
			for _, predicate in predicates do
				if not predicate(value) then
					return false
				end
			end
			return true
		end)
	end

	function query_object.where_any(
		self: query_types.Query<Result>,
		predicates: { query_types.Filter<Result> }
	): query_types.Query<Result>
		return self:where(function(value: Result): boolean
			for _, predicate in predicates do
				if predicate(value) then
					return true
				end
			end
			return false
		end)
	end

	function query_object.where_none(
		self: query_types.Query<Result>,
		predicates: { query_types.Filter<Result> }
	): query_types.Query<Result>
		return self:where(function(value: Result): boolean
			for _, predicate in predicates do
				if predicate(value) then
					return false
				end
			end
			return true
		end)
	end

	function query_object.where_not(
		self: query_types.Query<Result>,
		predicate: query_types.Filter<Result>
	): query_types.Query<Result>
		return self:where(function(value: Result): boolean
			return not predicate(value)
		end)
	end

	-- TODO(luau): generic methods attached after table creation.
	return query_object :: query_types.Query<Result>
end

function query.new<Result>(
	matchers: { query_types.Matcher },
	normalize: query_types.Normalizer<Result>
): query_types.Query<Result>
	return create_query(function(root: query_types.SyntaxRoot): { Result }
		const values = {}

		walk(root, function(node: query_types.SyntaxNode)
			for _, matcher in matchers do
				if not matcher(node) then
					return
				end
			end

			table.insert(values, normalize(node))
		end)

		return values
	end)
end

function query.from_evaluator<Result>(evaluator: (root: query_types.SyntaxRoot) -> { Result }): query_types.Query<Result>
	return create_query(evaluator)
end

match.stat_function = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "function" and field(node, "func") ~= nil
end
match.local_function = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "localfunction"
end
match.expression_function = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "function" and field(node, "func") == nil
end
match.any_function = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "function" or field(node, "tag") == "localfunction"
end
match.any_call = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "call"
end
match.any_assignment = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "assign" or field(node, "tag") == "compoundassign"
end
match.any_local = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "local"
end
match.any_loop = function(node: query_types.SyntaxNode): boolean
	const tag = field(node, "tag")
	return tag == "while" or tag == "repeat" or tag == "for" or tag == "forin"
end
match.any_if = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "conditional"
end
match.any_return = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "return"
end
match.any_binary = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "binary"
end
match.any_unary = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "unary"
end
match.any_string = function(node: query_types.SyntaxNode): boolean
	const tag = field(node, "tag")
	return tag == "string" or tag == "interpolatedstring"
end
match.any_table = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "table"
end
match.any_type = function(node: query_types.SyntaxNode): boolean
	return field(node, "kind") == "type"
end
match.type_alias = function(node: query_types.SyntaxNode): boolean
	const tag = field(node, "tag")
	return tag == "typealias" or tag == "typefunction"
end
match.type_function = function(node: query_types.SyntaxNode): boolean
	return field(node, "tag") == "function" and field(node, "kind") == "type"
end
match.where = function(matcher: query_types.Matcher, predicate: query_types.Matcher): query_types.Matcher
	return function(node: query_types.SyntaxNode): boolean
		return matcher(node) and predicate(node)
	end
end

query.match = match

local filters = {}

function filters.all<Result>(predicates: { query_types.Filter<Result> }): query_types.Filter<Result>
	return function(value: Result): boolean
		for _, predicate in predicates do
			if not predicate(value) then
				return false
			end
		end

		return true
	end
end

function filters.any<Result>(predicates: { query_types.Filter<Result> }): query_types.Filter<Result>
	return function(value: Result): boolean
		for _, predicate in predicates do
			if predicate(value) then
				return true
			end
		end

		return false
	end
end

function filters.not_<Result>(predicate: query_types.Filter<Result>): query_types.Filter<Result>
	return function(value: Result): boolean
		return not predicate(value)
	end
end

function filters.none<Result>(predicates: { query_types.Filter<Result> }): query_types.Filter<Result>
	return filters.not_(filters.any(predicates))
end

function filters.xor<Result>(
	first: query_types.Filter<Result>,
	second: query_types.Filter<Result>
): query_types.Filter<Result>
	return function(value: Result): boolean
		return first(value) ~= second(value)
	end
end

function filters.always<Result>(): query_types.Filter<Result>
	return function(): boolean
		return true
	end
end

function filters.never<Result>(): query_types.Filter<Result>
	return function(): boolean
		return false
	end
end

function filters.equals<Result>(expected: Result): query_types.Filter<Result>
	return function(value: Result): boolean
		return value == expected
	end
end

function filters.not_equals<Result>(expected: Result): query_types.Filter<Result>
	return filters.not_(filters.equals(expected))
end

function filters.one_of<Result>(expected: { Result }): query_types.Filter<Result>
	return function(value: Result): boolean
		for _, candidate in expected do
			if value == candidate then
				return true
			end
		end
		return false
	end
end

function filters.not_one_of<Result>(expected: { Result }): query_types.Filter<Result>
	return filters.not_(filters.one_of(expected))
end

function filters.is_nil<Result>(): query_types.Filter<Result?>
	return function(value: Result?): boolean
		return value == nil
	end
end

function filters.is_present<Result>(): query_types.Filter<Result?>
	return function(value: Result?): boolean
		return value ~= nil
	end
end

function filters.by<Result, Selected>(
	selector: (Result) -> Selected,
	predicate: query_types.Filter<Selected>
): query_types.Filter<Result>
	return function(value: Result): boolean
		return predicate(selector(value))
	end
end

function filters.equals_by<Result, Selected>(
	selector: (Result) -> Selected?,
	expected: Selected
): query_types.Filter<Result>
	return function(value: Result): boolean
		return selector(value) == expected
	end
end

function filters.one_of_by<Result, Selected>(
	selector: (Result) -> Selected?,
	expected: { Selected }
): query_types.Filter<Result>
	const predicate = filters.one_of(expected)
	return function(value: Result): boolean
		const selected = selector(value)
		if selected == nil then
			return false
		end
		return predicate(selected)
	end
end

local string_filters = {}

function string_filters.equals(expected: string, ignore_case: boolean?): query_types.Filter<string>
	const comparison = if ignore_case then string.lower(expected) else expected
	return function(value: string): boolean
		return (if ignore_case then string.lower(value) else value) == comparison
	end
end

function string_filters.contains(needle: string, ignore_case: boolean?): query_types.Filter<string>
	const comparison = if ignore_case then string.lower(needle) else needle
	return function(value: string): boolean
		const source = if ignore_case then string.lower(value) else value
		return source:find(comparison, 1, true) ~= nil
	end
end

function string_filters.starts_with(prefix: string, ignore_case: boolean?): query_types.Filter<string>
	const comparison = if ignore_case then string.lower(prefix) else prefix
	return function(value: string): boolean
		const source = if ignore_case then string.lower(value) else value
		return source:sub(1, #comparison) == comparison
	end
end

function string_filters.ends_with(suffix: string, ignore_case: boolean?): query_types.Filter<string>
	const comparison = if ignore_case then string.lower(suffix) else suffix
	return function(value: string): boolean
		const source = if ignore_case then string.lower(value) else value
		return comparison == "" or source:sub(-#comparison) == comparison
	end
end

function string_filters.matches(pattern: string): query_types.Filter<string>
	return function(value: string): boolean
		return value:match(pattern) ~= nil
	end
end

function string_filters.empty(): query_types.Filter<string>
	return string_filters.equals("")
end

function string_filters.non_empty(): query_types.Filter<string>
	return filters.not_(string_filters.empty())
end

function string_filters.has_length(length: number): query_types.Filter<string>
	return function(value: string): boolean
		return #value == length
	end
end

function string_filters.minimum_length(minimum: number): query_types.Filter<string>
	return function(value: string): boolean
		return #value >= minimum
	end
end

function string_filters.maximum_length(maximum: number): query_types.Filter<string>
	return function(value: string): boolean
		return #value <= maximum
	end
end

function string_filters.length_between(minimum: number, maximum: number): query_types.Filter<string>
	return function(value: string): boolean
		return #value >= minimum and #value <= maximum
	end
end

filters.string = string_filters

local number_filters = {}

function number_filters.greater_than(minimum: number): query_types.Filter<number>
	return function(value: number): boolean
		return value > minimum
	end
end

function number_filters.at_least(minimum: number): query_types.Filter<number>
	return function(value: number): boolean
		return value >= minimum
	end
end

function number_filters.less_than(maximum: number): query_types.Filter<number>
	return function(value: number): boolean
		return value < maximum
	end
end

function number_filters.at_most(maximum: number): query_types.Filter<number>
	return function(value: number): boolean
		return value <= maximum
	end
end


function number_filters.between(minimum: number, maximum: number): query_types.Filter<number>
	return function(value: number): boolean
		return value >= minimum and value <= maximum
	end
end


function number_filters.outside(minimum: number, maximum: number): query_types.Filter<number>
	return function(value: number): boolean
		return value < minimum or value > maximum
	end
end

function number_filters.positive(): query_types.Filter<number>
	return number_filters.greater_than(0)
end

function number_filters.negative(): query_types.Filter<number>
	return number_filters.less_than(0)
end

function number_filters.zero(): query_types.Filter<number>
	return filters.equals(0)
end

function number_filters.integer(): query_types.Filter<number>
	return function(value: number): boolean
		return value % 1 == 0
	end
end

function number_filters.finite(): query_types.Filter<number>
	return function(value: number): boolean
		return value == value and value ~= math.huge and value ~= -math.huge
	end
end

filters.number = number_filters

local array_filters = {}

function array_filters.empty<Result>(): query_types.Filter<{ Result }>
	return function(value: { Result }): boolean
		return #value == 0
	end
end

function array_filters.non_empty<Result>(): query_types.Filter<{ Result }>
	return filters.not_(array_filters.empty())
end

function array_filters.has_length<Result>(length: number): query_types.Filter<{ Result }>
	return function(value: { Result }): boolean
		return #value == length
	end
end

function array_filters.minimum_length<Result>(minimum: number): query_types.Filter<{ Result }>
	return function(value: { Result }): boolean
		return #value >= minimum
	end
end

function array_filters.maximum_length<Result>(maximum: number): query_types.Filter<{ Result }>
	return function(value: { Result }): boolean
		return #value <= maximum
	end
end

function array_filters.length_between<Result>(minimum: number, maximum: number): query_types.Filter<{ Result }>
	return function(value: { Result }): boolean
		return #value >= minimum and #value <= maximum
	end
end

function array_filters.contains<Result>(expected: Result): query_types.Filter<{ Result }>
	return function(value: { Result }): boolean
		for _, item in value do
			if item == expected then
				return true
			end
		end
		return false
	end
end

function array_filters.any<Result>(predicate: query_types.Filter<Result>): query_types.Filter<{ Result }>
	return function(value: { Result }): boolean
		for _, item in value do
			if predicate(item) then
				return true
			end
		end
		return false
	end
end

function array_filters.all<Result>(predicate: query_types.Filter<Result>): query_types.Filter<{ Result }>
	return function(value: { Result }): boolean
		for _, item in value do
			if not predicate(item) then
				return false
			end
		end
		return true
	end
end

function array_filters.none<Result>(predicate: query_types.Filter<Result>): query_types.Filter<{ Result }>
	return filters.not_(array_filters.any(predicate))
end

filters.array = array_filters

local boolean_filters = {}

function boolean_filters.is_true(): query_types.Filter<boolean>
	return filters.equals(true)
end

function boolean_filters.is_false(): query_types.Filter<boolean>
	return filters.equals(false)
end

filters.boolean = boolean_filters

query.filters = filters

return query
