--!strict

const query = require("@kern/query")
const query_types = require("@kern/query/types")

export type CommentInfo = {
	text: string,
	content: string,
	is_multiline: boolean,
	is_pragma: boolean,
	is_documentation: boolean,
	is_todo: boolean,
	is_fixme: boolean,
	span: query_types.Span,
}

local comments = {}
local containing_queries: { [string]: query_types.Query<CommentInfo> } = {}

const function content_from_text(text: string): string
	if text:sub(1, 2) ~= "--" then
		return text
	end

	const long_equals = text:match("^%-%-%[(=*)%[")
	if long_equals ~= nil then
		const opening_length = 4 + #long_equals
		const closing_length = 2 + #long_equals
		return text:sub(opening_length + 1, -(closing_length + 1)):match("^%s*(.-)%s*$") or ""
	end

	return text:sub(3):match("^%s?(.-)%s*$") or ""
end

const function normalize(node: any): CommentInfo
	const text = if node.text ~= nil then tostring(node.text) else ""
	const content = content_from_text(text)
	const upper_content = string.upper(content)
	return {
		text = text,
		content = content,
		is_multiline = node.tag == "blockcomment" or text:sub(1, 4) == "--[[",
		is_pragma = text:sub(1, 3) == "--!",
		is_documentation = text:sub(1, 3) == "---" or text:match("^%-%-%[=*%[") ~= nil,
		is_todo = upper_content:find("TODO", 1, true) ~= nil,
		is_fixme = upper_content:find("FIXME", 1, true) ~= nil,
		span = node.location,
	}
end

const any_query = query.new({
	function(node: any): boolean
		return node.tag == "comment" or node.tag == "blockcomment"
	end,
}, normalize)

comments.any = any_query
comments.single_line = any_query:where(function(value: CommentInfo): boolean
	return not value.is_multiline
end)
comments.multiline = any_query:where(function(value: CommentInfo): boolean
	return value.is_multiline
end)
comments.pragma = any_query:where(function(value: CommentInfo): boolean
	return value.is_pragma
end)
comments.documentation = any_query:where(function(value: CommentInfo): boolean
	return value.is_documentation
end)
comments.todo = any_query:where(function(value: CommentInfo): boolean
	return value.is_todo
end)
comments.fixme = any_query:where(function(value: CommentInfo): boolean
	return value.is_fixme
end)
comments.empty = any_query:where(function(value: CommentInfo): boolean
	return value.content == ""
end)

function comments.containing(pattern: string): query_types.Query<CommentInfo>
	if containing_queries[pattern] ~= nil then
		return containing_queries[pattern]
	end
	const value = any_query:where(function(value: CommentInfo): boolean
		return value.text:match(pattern) ~= nil
	end)
	containing_queries[pattern] = value
	return value
end

function comments.containing_text(expected: string, ignore_case: boolean?): query_types.Query<CommentInfo>
	const comparison = if ignore_case then string.lower(expected) else expected
	return any_query:where(function(value: CommentInfo): boolean
		const content = if ignore_case then string.lower(value.content) else value.content
		return content:find(comparison, 1, true) ~= nil
	end)
end

function comments.equal_to(expected: string, ignore_case: boolean?): query_types.Query<CommentInfo>
	const comparison = if ignore_case then string.lower(expected) else expected
	return any_query:where(function(value: CommentInfo): boolean
		return (if ignore_case then string.lower(value.content) else value.content) == comparison
	end)
end

function comments.starting_with(prefix: string, ignore_case: boolean?): query_types.Query<CommentInfo>
	const comparison = if ignore_case then string.lower(prefix) else prefix
	return any_query:where(function(value: CommentInfo): boolean
		const content = if ignore_case then string.lower(value.content) else value.content
		return content:sub(1, #comparison) == comparison
	end)
end

function comments.ending_with(suffix: string, ignore_case: boolean?): query_types.Query<CommentInfo>
	const comparison = if ignore_case then string.lower(suffix) else suffix
	return any_query:where(function(value: CommentInfo): boolean
		const content = if ignore_case then string.lower(value.content) else value.content
		return comparison == "" or content:sub(-#comparison) == comparison
	end)
end

function comments.with_minimum_length(minimum: number): query_types.Query<CommentInfo>
	return any_query:where(function(value: CommentInfo): boolean
		return #value.content >= minimum
	end)
end

function comments.with_maximum_length(maximum: number): query_types.Query<CommentInfo>
	return any_query:where(function(value: CommentInfo): boolean
		return #value.content <= maximum
	end)
end

return comments
