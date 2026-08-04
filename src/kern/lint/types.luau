--!strict

const scope_types = require("@kern/scope")
const syntax_types = require("@kern/syntax/types")
const query_types = require("@kern/query/types")

export type Severity = "hint" | "info" | "warn" | "error"

export type DiagnosticNote = {
	message: string,
	span: syntax_types.Span?,
}

export type DiagnosticFix = {
	span: syntax_types.Span,
	replacement: string,
}

export type ReportOptions = {
	severity: Severity?,
	notes: { DiagnosticNote }?,
	fix: DiagnosticFix?,
}

export type Diagnostic = {
	rule: string,
	component: string,
	severity: Severity,
	message: string,
	file_path: string,
	span: syntax_types.Span,
	line: number,
	column: number,
	notes: { DiagnosticNote },
	fix: DiagnosticFix?,
}

export type LintContext = {
	source: string,
	file_path: string,
	project_root: string,
	report: (self: LintContext, span: syntax_types.Span, message: string, options: ReportOptions?) -> (),
}

export type LintDefinition = {
	description: string?,
	severity: Severity?,
	scope: scope_types.Scope?,
	run: (tree: query_types.SyntaxRoot, context: LintContext) -> (),
}

export type LintRule = {
	kind: "lint",
	name: string,
	description: string,
	severity: Severity,
	scope: scope_types.Scope?,
	run: (tree: query_types.SyntaxRoot, context: LintContext) -> (),
}

return nil
