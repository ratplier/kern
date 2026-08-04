--!strict

const types = require("@kern/lint/types")

local diagnostic = {}

const severity_order: { [types.Severity]: number } = {
	hint = 1,
	info = 2,
	warn = 3,
	error = 4,
}

function diagnostic.compare(first: types.Diagnostic, second: types.Diagnostic): boolean
	if first.file_path ~= second.file_path then
		return first.file_path < second.file_path
	end
	if first.span.start ~= second.span.start then
		return first.span.start < second.span.start
	end
	if first.component ~= second.component then
		return first.component < second.component
	end
	if first.rule ~= second.rule then
		return first.rule < second.rule
	end

	return first.message < second.message
end

function diagnostic.meets_severity(value: types.Diagnostic, minimum: types.Severity): boolean
	return severity_order[value.severity] >= severity_order[minimum]
end

return diagnostic
