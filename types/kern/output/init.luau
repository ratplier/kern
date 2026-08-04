--!nocheck

const Filesystem = require("@kern/fs/types")

--[=[
	@within Output

	Configures directory output for project builds.

	Use `source_root` to flatten one source tree into the output directory.
	Use `include` and `exclude` to preserve several project-relative files and folders,
	including non-Luau artifacts such as Rojo project files.
]=]
export type OutputConfig = {
	name: string?,
	path: string,
	source_root: string?,
	include: { string }?,
	exclude: { string }?,
	clean: boolean?,
	include_packages: boolean?,
}

export type OutputErrorCode = "output_error" | "filesystem_error"
export type OutputError = { code: OutputErrorCode, message: string, path: string? }
export type BuildFile = { file_path: string, source: string }
export type EmitResult = { ok: true, files_written: number } | { ok: false, error: OutputError }

--[=[
	@within Output

	Writes transformed project files to an output destination.
]=]
export type OutputEmitter = {
	kind: "output",
	name: string,
	path: string,
	source_root: string?,
	include: { string },
	exclude: { string },
	clean: boolean,
	include_packages: boolean,
	output_path: (self: OutputEmitter, source_path: string, project_root: string) -> string,
	emit: (self: OutputEmitter, files: { BuildFile }, file_system: Filesystem.Filesystem, project_root: string) -> EmitResult,
}

local output = {}

--[=[
	@within Output

	Creates a directory output emitter.

	@param config The output directory, selected artifacts, and write behavior
	@return A directory output emitter
]=]
function output.new(config: OutputConfig): OutputEmitter
	return nil :: any
end

--[=[
	@within Output

	Creates a directory output emitter.

	@param config The output directory, selected artifacts, and write behavior
	@return A directory output emitter
]=]
output.directory = output.new

return output
