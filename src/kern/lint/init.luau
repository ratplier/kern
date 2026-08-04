--!strict

const types = require("@kern/lint/types")
const context = require("@kern/lint/context")
const diagnostic = require("@kern/lint/diagnostic")

local lint = {}

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

	error(`kern: invalid lint severity '{value}'`, 2)
end

const function new(name: string, definition: types.LintDefinition): types.LintRule
	if name == "" then
		error("kern: lint rule name cannot be empty", 2)
	end

	const severity: types.Severity = validate_severity(definition.severity or "warn")

	const rule: types.LintRule = {
		kind = "lint",
		name = name,
		description = definition.description or "",
		severity = severity,
		scope = definition.scope,
		run = definition.run,
	}
	return rule
end

lint.new = new
lint.context = context.new
lint.compare = diagnostic.compare
lint.meets_severity = diagnostic.meets_severity

return lint
