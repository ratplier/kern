--!strict

const parse = require("@kern/syntax/parse")
const parents = require("@kern/syntax/parents")
const replacement = require("@kern/syntax/replacement")
const quote = require("@kern/syntax/quote")

return {
	parse = parse.source,
	parse_block = parse.block,
	parse_expression = parse.expression,
	parents = parents,
	replacement = replacement,
	quote = quote,
}
