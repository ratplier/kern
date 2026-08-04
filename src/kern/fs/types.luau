--!strict

const result = require("@kern/core/result")

export type FileOperationError = {
	code: "filesystem_error",
	message: string,
	path: string?,
}

export type OperationResult<T> = result.Result<T, FileOperationError>

export type Filesystem = {
	is_file: (self: Filesystem, path: string) -> boolean,
	is_directory: (self: Filesystem, path: string) -> boolean,

	read_file: (self: Filesystem, path: string) -> OperationResult<string>,
	write_file: (self: Filesystem, path: string, source: string) -> OperationResult<nil>,

	create_directory: (self: Filesystem, path: string) -> OperationResult<nil>,
	remove_directory: (self: Filesystem, path: string) -> OperationResult<nil>,

	find: (self: Filesystem, patterns: { string }, exclusions: { string }) -> OperationResult<{ string }>,
}

return nil
