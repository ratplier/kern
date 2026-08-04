--!strict

const syntax = require("@std/syntax")
const printer = require("@std/syntax/printer")
const types = require("@kern/syntax/types")

local quote = {}

const function parse_block(source: string): types.SyntaxRoot
	const success, result = pcall(syntax.parseBlock, source)
	if not success then
		error(`kern: could not quote Luau source: {result}`, 3)
	end
	return result :: types.SyntaxRoot
end

function quote.node(source: string): types.SyntaxNode
	if source:match("^%s*$") ~= nil then
		error("kern: cannot quote empty Luau source", 2)
	end

	const block_success, block = pcall(syntax.parseBlock, source)
	if block_success then
		const root = block :: types.SyntaxRoot
		if #root.statements == 1 then
			return root.statements[1]
		end
		return root
	end

	const expression_success, expression = pcall(syntax.parseExpr, source)
	if expression_success then
		return expression :: types.SyntaxExpression
	end

	error(`kern: could not quote Luau source: {expression}`, 2)
end

function quote.expression(source: string): types.SyntaxExpression
	const success, result = pcall(syntax.parseExpr, source)
	if not success then
		error(`kern: could not quote Luau expression: {result}`, 2)
	end
	return result :: types.SyntaxExpression
end

function quote.block(source: string): types.SyntaxRoot
	return parse_block(source)
end

function quote.source(node: types.SyntaxNode): string
	const value = node :: any
	if typeof(value) ~= "table" or value.location == nil then
		error("kern: expected a syntax node as replacement", 2)
	end
	return printer.printNode(node)
end

return quote
