--!strict

const replacement = require("@kern/syntax/replacement")
const scope_types = require("@kern/scope")
const syntax_types = require("@kern/syntax/types")
const location = require("@kern/syntax/location")
const transform_types = require("@kern/transform")
const require_types = require("@kern/require")
const quote = require("@kern/syntax/quote")

type TransformState = transform_types.TransformContext & {
	replacements: { replacement.Replacement },
}

local context = {}

const function comment_block_finish(source: string, start: number): number?
	const equals = source:sub(start):match("^%-%-%[(=*)%[")
	if equals == nil then
		return nil
	end
	const _, opening_finish = source:find(`--[{equals}[`, start, true)
	if opening_finish == nil then
		return nil
	end
	const _, finish = source:find(`]{equals}]`, opening_finish + 1, true)
	return finish
end

const function import_offset(source: string): number
	local cursor = if source:sub(1, 3) == "\239\187\191" then 4 else 1

	while cursor <= #source do
		local content = cursor
		while source:sub(content, content) == " " or source:sub(content, content) == "\t" do
			content += 1
		end

		const character = source:sub(content, content)
		if character == "\r" or character == "\n" then
			if character == "\r" and source:sub(content + 1, content + 1) == "\n" then
				content += 1
			end
			cursor = content + 1
			continue
		end

		if source:sub(content, content + 1) ~= "--" then
			break
		end

		const block_finish = comment_block_finish(source, content)
		if block_finish ~= nil then
			cursor = block_finish + 1
		else
			const newline = source:find("\n", content + 2, true)
			if newline == nil then
				return #source
			end
			cursor = newline + 1
		end
	end

	return cursor - 1
end

const function formatted_import(source: string, existing_source: string, offset: number): string
	const normalized = (source:gsub("%s+$", ""))
	if normalized == "" then
		error("kern: import source cannot be empty", 3)
	end
	const leading_newline = if offset > 0 and existing_source:sub(offset, offset) ~= "\n" then "\n" else ""
	return `{leading_newline}{normalized}\n\n`
end

const function escaped_pattern(value: string): string
	return (value:gsub("([^%w])", "%%%1"))
end

const function has_import(source: string, binding: string, request: string): boolean
	const assignment = `{escaped_pattern(binding)}%s*=%s*require%s*%(%s*["']{escaped_pattern(request)}["']%s*%)`
	return source:match(`local%s+{assignment}`) ~= nil or source:match(`const%s+{assignment}`) ~= nil
end

const function validate_import(binding: string, request: string)
	if binding:match("^[%a_][%w_]*$") == nil then
		error(`kern: invalid import binding '{binding}'`, 3)
	end
	if request == "" or request:find('["\'\r\n]') ~= nil then
		error("kern: import request must be a non-empty single-line path", 3)
	end
end

const function span_from_target(source: string, target: any): syntax_types.Span
	-- TODO(luau): mixed span and AST target fields.
	const raw_target = target :: any
	if raw_target.start ~= nil and raw_target.finish ~= nil then
		return raw_target
	end

	-- TODO(luau): missing Lute span-bearing node type.
	const node = target :: any
	const node_location = if node.location ~= nil then node.location else node
	const start = location.offset_from_line_column(source, node_location.beginLine, node_location.beginColumn)
	const finish = location.offset_from_line_column(source, node_location.endLine, node_location.endColumn)

	return { start = start, finish = finish }
end

const function span_from_node(source: string, node: syntax_types.SyntaxNode): syntax_types.Span
	const value = node :: any
	if typeof(value) ~= "table" or value.location == nil then
		error("kern: expected a syntax node; use replace_range or remove_range for a span", 3)
	end
	return span_from_target(source, node)
end

const function new(
	source: string,
	file_path: string,
	project_root: string,
	rule: transform_types.TransformRule,
	scope_map: scope_types.ScopeMap?,
	replacements: { replacement.Replacement },
	resolved_requires: { require_types.ResolvedRequire }?
): TransformState
	local context_value: TransformState
	const inserted_imports = {}

	const function add(target: syntax_types.SyntaxNode | syntax_types.Span, replacement_source: string)
		const span = span_from_target(source, target)
		if rule.scope ~= nil and scope_map ~= nil and scope_map:is_suppressed(rule.scope.namespace, span) then
			return
		end

		const replacement_value: replacement.Replacement = {
			owner_kind = "transform",
			owner_name = rule.name,
			span = span,
			source = replacement_source,
		}
		table.insert(replacements, replacement_value)
	end

	context_value = {
		source = source,
		file_path = file_path,
		project_root = project_root,
		resolved_requires = resolved_requires,
		replacements = replacements,
		replace = function(_self, target, value)
			add(span_from_node(source, target), quote.source(value))
		end,
		remove = function(_self, target)
			add(span_from_node(source, target), "")
		end,
		replace_range = function(_self, target, value)
			add(target, value)
		end,
		remove_range = function(_self, target)
			add(target, "")
		end,
		insert_before = function(_self, target, value)
			const span = span_from_target(source, target)
			add({ start = span.start, finish = span.start }, value)
		end,
		insert_after = function(_self, target, value)
			const span = span_from_target(source, target)
			add({ start = span.finish, finish = span.finish }, value)
		end,
		insert_import = function(_self, value)
			const offset = import_offset(source)
			const normalized = (value:gsub("%s+$", ""))
			if inserted_imports[normalized] then
				return
			end
			inserted_imports[normalized] = true
			add({ start = offset, finish = offset }, formatted_import(normalized, source, offset))
		end,
		ensure_import = function(self, binding, request)
			validate_import(binding, request)
			const key = `{binding}\0{request}`
			if inserted_imports[key] or has_import(source, binding, request) then
				return false
			end
			inserted_imports[key] = true
			self:insert_import(`const {binding} = require("{request}")`)
			return true
		end,
		-- TODO(luau): incremental transform state assembly.
	} :: TransformState

	return context_value
end

context.new = new

return context
