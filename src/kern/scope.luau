--!strict

const result = require("@kern/core/result")
const syntax_types = require("@kern/syntax/types")

export type ScopeBinding = "next" | "range" | "range_end" | "file"

export type Scope = {
	namespace: string,
	directives: { [string]: ScopeBinding },
}

export type Suppression = {
	namespace: string,
	start: number,
	finish: number,
}

export type ScopeMap = {
	suppressions: { Suppression },
	is_suppressed: (self: ScopeMap, namespace: string, span: syntax_types.Span) -> boolean,
}

export type ScopeError = {
	code: "scope_error",
	message: string,
	span: syntax_types.Span?,
}

type Directive = {
	namespace: string,
	binding: ScopeBinding,
	span: { start: number, finish: number },
	line_finish: number,
	executable_seen: boolean,
}

local scope = {}

const function new(config: {
	namespace: string,
	directives: { [string]: ScopeBinding },
}): Scope
	if config.namespace == "" then
		error("kern: scope namespace cannot be empty", 2)
	end

	const copied: { [string]: ScopeBinding } = {}
	for name, binding in config.directives do
		if name == "" then
			error("kern: scope directive name cannot be empty", 2)
		end
		if binding ~= "next" and binding ~= "range" and binding ~= "range_end" and binding ~= "file" then
			error(`kern: invalid scope binding '{binding}'`, 2)
		end
		copied[name] = binding
	end

	return {
		namespace = config.namespace,
		directives = copied,
	}
end

const function line_finish(source: string, start: number): number
	const newline = source:find("\n", start, true)
	return if newline == nil then #source else newline - 1
end

const function next_statement(source: string, start: number): syntax_types.Span?
	local cursor = start + 1
	while cursor <= #source do
		const finish = line_finish(source, cursor)
		const content = source:sub(cursor, finish)
		if content:match("%S") ~= nil and content:match("^%s*%-%-") == nil then
			return { start = cursor - 1, finish = finish }
		end
		cursor = finish + 2
	end
	return nil
end

const function directives(source: string, value: Scope): { Directive }
	const output = {}
	local offset = 1
	local executable_seen = false

	for line in source:gmatch("[^\n]*\n?") do
		const content = line:gsub("\n$", ""):gsub("\r$", "")
		const comment_start = content:find("%-%-")
		const before_comment = if comment_start == nil then content else content:sub(1, comment_start - 1)

		if before_comment:match("%S") ~= nil then
			executable_seen = true
		end

		if comment_start ~= nil then
			const comment = content:sub(comment_start)
			const namespace, name = comment:match("^%-%- ([%w_]+): ([%w_]+)$")
			const binding = if namespace == value.namespace and name ~= nil then value.directives[name] else nil

			if namespace ~= nil and binding ~= nil then
				table.insert(output, {
					namespace = namespace,
					binding = binding,
					span = { start = offset + comment_start - 1, finish = offset + #content - 1 },
					line_finish = offset + #content - 1,
					executable_seen = executable_seen,
				})
			end
		end

		offset += #line
		if #line == 0 then
			break
		end
	end

	return output
end

const function parse(source: string, value: Scope): result.Result<ScopeMap, ScopeError>
	const found = directives(source, value)
	const suppressions = {}
	local open_ranges: { Directive } = {}

	for _, directive in found do
		if directive.binding == "next" then
			const statement = next_statement(source, directive.line_finish)
			if statement ~= nil then
				table.insert(suppressions, {
					namespace = directive.namespace,
					start = statement.start,
					finish = statement.finish,
				})
			end
		elseif directive.binding == "file" then
			if directive.executable_seen then
				return {
					ok = false,
					error = {
						code = "scope_error",
						message = "file scope directive must precede executable code",
						span = directive.span,
					},
				}
			end
			table.insert(
				suppressions,
				{ namespace = directive.namespace, start = directive.span.start, finish = #source }
			)
		elseif directive.binding == "range" then
			table.insert(open_ranges, directive)
		elseif directive.binding == "range_end" then
			const open_range = open_ranges[#open_ranges]
			if open_range == nil then
				return {
					ok = false,
					error = {
						code = "scope_error",
						message = "scope range end without range start",
						span = directive.span,
					},
				}
			end
			table.insert(
				suppressions,
				{ namespace = directive.namespace, start = open_range.span.start, finish = directive.span.finish }
			)
			table.remove(open_ranges)
		end
	end

	if #open_ranges > 0 then
		const open_range = open_ranges[#open_ranges]
		return { ok = false, error = { code = "scope_error", message = "unclosed scope range", span = open_range.span } }
	end

	const map_value: ScopeMap = {
		suppressions = suppressions,
		is_suppressed = function(self: ScopeMap, namespace: string, span: syntax_types.Span): boolean
			for _, suppression in self.suppressions do
				if
					suppression.namespace == namespace
					and suppression.start <= span.finish
					and suppression.finish >= span.start
				then
					return true
				end
			end
			return false
		end,
	}

	return { ok = true, value = map_value }
end

scope.new = new
scope.parse = parse

return scope
