--!nocheck

const Syntax = require("@kern/syntax/types")

export type ProcessingErrorCode =
	"parse_error" | "filesystem_error" | "scope_error" | "replacement_conflict" | "missing_module"
	| "ambiguous_module" | "unknown_alias" | "path_escape" | "unsupported_require" | "module_cycle"
	| "invalid_entry" | "output_error" | "rule_error"

--[=[
	@within Errors

	A file-processing failure returned by a project operation.
]=]
export type ProcessingError = {
	code: ProcessingErrorCode,
	message: string,
	file_path: string?,
	span: Syntax.Span?,
	line: number?,
	column: number?,
	notes: { string },
}

return {}
