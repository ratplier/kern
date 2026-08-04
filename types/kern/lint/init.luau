--!nocheck

const Query = require("@kern/query/types")
const Scope = require("@kern/scope")
const Syntax = require("@kern/syntax/types")

--[=[
	@within Lint

	The severity assigned to a lint diagnostic.
]=]
export type Severity = "hint" | "info" | "warn" | "error"

--[=[
	@within Lint

	Data and reporting operations available while a lint rule runs.
]=]
export type LintContext = {
	source: string,
	file_path: string,
	project_root: string,
	report: (self: LintContext, span: Syntax.Span, message: string, options: ReportOptions?) -> (),
}

--[=[
	@within Lint

	Optional diagnostic details supplied when reporting a problem.
]=]
export type ReportOptions = {
	severity: Severity?,
	notes: { DiagnosticNote }?,
	fix: DiagnosticFix?,
}

export type DiagnosticNote = { message: string, span: Syntax.Span? }
export type DiagnosticFix = { span: Syntax.Span, replacement: string }

--[=[
	@within Lint

	A problem reported by a lint rule.
]=]
export type Diagnostic = {
	rule: string,
	component: string,
	severity: Severity,
	message: string,
	file_path: string,
	span: Syntax.Span,
	line: number,
	column: number,
	notes: { DiagnosticNote },
	fix: DiagnosticFix?,
}

--[=[
	@within Lint

	Describes the behavior and defaults of a lint rule.
]=]
export type LintDefinition = {
	description: string?,
	severity: Severity?,
	scope: Scope.Scope?,
	run: (tree: Query.SyntaxRoot, context: LintContext) -> (),
}

--[=[
	@within Lint

	A validated lint rule that can be placed in a component or project.
]=]
export type LintRule = {
	kind: "lint",
	name: string,
	description: string,
	severity: Severity,
	scope: Scope.Scope?,
	run: (tree: Query.SyntaxRoot, context: LintContext) -> (),
}

local lint = {}

--[=[
	@within Lint

	Creates a named lint rule.

	@param name A unique rule name
	@param definition The callback and optional rule settings
	@return The validated lint rule
]=]
function lint.new(name: string, definition: LintDefinition): LintRule
	return nil :: any
end

--[=[
	@within Lint

	Creates a lint context for a source file.

	@param source The source being linted
	@param file_path The source file path
	@param project_root The owning project root
	@param rule The active lint rule
	@param component_name The component containing the rule
	@param scope_map Parsed suppressions for the source
	@return A context that reports diagnostics
]=]
function lint.context(
	source: string,
	file_path: string,
	project_root: string,
	rule: LintRule,
	component_name: string,
	scope_map: Scope.ScopeMap?
): LintContext
	return nil :: any
end

--[=[
	@within Lint

	Orders two diagnostics deterministically by file and source position.

	@param left The first diagnostic
	@param right The second diagnostic
	@return Whether `left` sorts before `right`
]=]
function lint.compare(left: Diagnostic, right: Diagnostic): boolean
	return false
end

--[=[
	@within Lint

	Returns whether a severity meets a configured minimum severity.

	@param severity The diagnostic severity
	@param minimum The minimum accepted severity
	@return Whether the diagnostic meets the threshold
]=]
function lint.meets_severity(severity: Severity, minimum: Severity): boolean
	return false
end

return lint
