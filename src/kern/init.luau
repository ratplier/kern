--!strict

const component = require("@kern/component")
const project = require("@kern/project")
const lint = require("@kern/lint")
const transform = require("@kern/transform")
const scope = require("@kern/scope")
const query = require("@kern/query")
const query_types = require("@kern/query/types")
const compose = require("@kern/query/compose")
const catalog = require("@kern/query/builtins")
const syntax = require("@kern/syntax")
const require_resolver = require("@kern/require")
const output = require("@kern/output")

const function create_query<Result>(config: {
	matchers: { query_types.Matcher },
	normalize: query_types.Normalizer<Result>,
}): query_types.Query<Result>
	if #config.matchers == 0 then
		error("kern: query requires at least one matcher", 2)
	end
	return query.new(config.matchers, config.normalize)
end

return {
	component = component.new,
	project = project.new,
	lint = lint.new,
	transform = transform.new,
	require = require_resolver.new,
	output = output,
	scope = scope.new,
	query = create_query,
	filters = query.filters,
	compose = compose,
	match = query.match,
	calls = catalog.calls,
	functions = catalog.functions,
	locals = catalog.locals,
	types = catalog.types,
	tables = catalog.tables,
	control_flow = catalog.control_flow,
	strings = catalog.strings,
	operators = catalog.operators,
	modules = catalog.modules,
	comments = catalog.comments,
	parse = syntax.parse,
	parse_block = syntax.parse_block,
	parse_expression = syntax.parse_expression,
	quote = syntax.quote.node,
	quote_expression = syntax.quote.expression,
	quote_block = syntax.quote.block,
}
