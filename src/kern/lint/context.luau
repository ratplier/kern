--!strict

const location = require("@kern/syntax/location")
const scope_types = require("@kern/scope")
const syntax_types = require("@kern/syntax/types")
const types = require("@kern/lint/types")

type ContextState = types.LintContext & {
	diagnostics: { types.Diagnostic },
}

local context = {}

const function validate_severity(value: string): types.Severity
	if value == "hint" then
		return "hint"
	end
	if value == "info" then
		return "info"
	end
	if value == "warn" then
		return "warn"
	end
	if value == "error" then
		return "error"
	end

	error(`kern: invalid diagnostic severity '{value}'`, 2)
end

const function normalize_span(source: string, span: syntax_types.Span): syntax_types.Span
	-- TODO(luau): mixed kern and Lute span fields.
	const raw_span = span :: any
	if raw_span.start ~= nil and raw_span.finish ~= nil then
		return raw_span
	end

	return {
		start = location.offset_from_line_column(source, raw_span.beginLine, raw_span.beginColumn),
		finish = location.offset_from_line_column(source, raw_span.endLine, raw_span.endColumn),
	}
end

const function normalize_fix(source: string, fix: types.DiagnosticFix?): types.DiagnosticFix?
	if fix == nil then
		return nil
	end

	return {
		span = normalize_span(source, fix.span),
		replacement = fix.replacement,
	}
end

const function new(
	source: string,
	file_path: string,
	project_root: string,
	rule: types.LintRule,
	component_name: string,
	scope_map: scope_types.ScopeMap?
): ContextState
	local context_value: ContextState

	const function report(
		_self: types.LintContext,
		span: syntax_types.Span,
		message: string,
		options: types.ReportOptions?
	)
		const normalized_span = normalize_span(source, span)
		if
			rule.scope ~= nil
			and scope_map ~= nil
			and scope_map:is_suppressed(rule.scope.namespace, normalized_span)
		then
			return
		end

		const report_options: types.ReportOptions = if options == nil
			then {
				severity = nil,
				notes = nil,
				fix = nil,
			}
			else options
		const severity: types.Severity = if report_options.severity == nil
			then rule.severity
			else validate_severity(report_options.severity)
		const notes: { types.DiagnosticNote } = report_options.notes or {}
		const source_location = location.from_span(source, normalized_span)

		const diagnostic: types.Diagnostic = {
			rule = rule.name,
			component = component_name,
			severity = severity,
			message = message,
			file_path = file_path,
			span = normalized_span,
			line = source_location.line,
			column = source_location.column,
			notes = notes,
			fix = normalize_fix(source, report_options.fix),
		}
		table.insert(context_value.diagnostics, diagnostic)
	end

	const diagnostics: { types.Diagnostic } = {}

	context_value = {
		source = source,
		file_path = file_path,
		project_root = project_root,
		diagnostics = diagnostics,
		report = report,
	}

	return context_value
end

context.new = new

return context
