--!strict

const syntax = require("@std/syntax")
const types = require("@kern/syntax/types")

const parse = {}

const function parse_error(message: string, file_path: string?): types.ParseError
	return {
		code = "parse_error",
		message = message,
		file_path = file_path,
	}
end

const function parse_source(source: string, file_path: string?): types.ParseResult
	const success, result = pcall(function()
		return syntax.parse(source)
	end)

	if not success then
		return {
			ok = false,
			error = parse_error(tostring(result), file_path),
		}
	end

	return {
		ok = true,
		-- TODO(luau): erased Lute parse result after pcall.
		tree = result :: types.SyntaxTree,
	}
end

function parse.source(source: string, file_path: string?): types.ParseResult
	return parse_source(source, file_path)
end

function parse.block(source: string): types.ParseResult
	return parse_source(source, nil)
end

function parse.expression(source: string): types.ParseResult
	return parse_source(`return {source}`, nil)
end

return parse
