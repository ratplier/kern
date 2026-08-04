--!nocheck

const Result = require("@kern/core/result")

--[=[
	@within Filesystem

	A filesystem operation failure.
]=]
export type FileOperationError = {
	code: "filesystem_error",
	message: string,
	path: string?,
}

export type OperationResult<Value> = Result.Result<Value, FileOperationError>

--[=[
	@within Filesystem

	Filesystem interface accepted by a Kern project.
]=]
export type Filesystem = {
	is_file: (self: Filesystem, path: string) -> boolean,
	is_directory: (self: Filesystem, path: string) -> boolean,
	read_file: (self: Filesystem, path: string) -> OperationResult<string>,
	write_file: (self: Filesystem, path: string, source: string) -> OperationResult<nil>,
	create_directory: (self: Filesystem, path: string) -> OperationResult<nil>,
	remove_directory: (self: Filesystem, path: string) -> OperationResult<nil>,
	find: (self: Filesystem, patterns: { string }, exclusions: { string }) -> OperationResult<{ string }>,
}

return {}
