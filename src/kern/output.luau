--!strict

const file_system_types = require("@kern/fs/types")
const path = require("@kern/core/path")

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

export type OutputError = {
	code: OutputErrorCode,
	message: string,
	path: string?,
}

export type BuildFile = {
	file_path: string,
	source: string,
}

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
	emit: (
		self: OutputEmitter,
		files: { BuildFile },
		file_system: file_system_types.Filesystem,
		project_root: string
	) -> { ok: true, files_written: number } | { ok: false, error: OutputError },
}

local output = {}

const function failure(code: OutputErrorCode, message: string, output_path: string): { ok: false, error: OutputError }
	return { ok = false, error = { code = code, message = message, path = output_path } }
end

const function validate_relative_path(kind: string, value: string)
	const normalized = path.normalize(value)
	if path.is_absolute(value) or normalized == ".." or normalized:sub(1, 3) == "../" then
		error(`kern: {kind} must remain inside the project root`, 2)
	end
end

const function copy_paths(kind: string, values: { string }): { string }
	const copied = {}
	for index, value in values do
		if typeof(value) ~= "string" then
			error(`kern: output {kind}[{index}] must be a string`, 2)
		end
		if value == "" then
			error(`kern: output {kind} path cannot be empty`, 2)
		end
		validate_relative_path(`output {kind} path`, value)
		table.insert(copied, path.normalize(value))
	end
	return copied
end

const function rooted(project_root: string, value: string): string
	return if path.is_inside(project_root, value) then value else path.join(project_root, value)
end

const function expand_patterns(
	values: { string },
	file_system: file_system_types.Filesystem,
	project_root: string
): { string }
	const patterns = {}
	for _, value in values do
		const absolute = rooted(project_root, value)
		if file_system:is_directory(absolute) then
			table.insert(patterns, `{absolute}/**/*`)
		else
			table.insert(patterns, absolute)
		end
	end
	return patterns
end

const function select_files(
	self: OutputEmitter,
	file_system: file_system_types.Filesystem,
	project_root: string,
	output_root: string
): { ok: true, files: { string } } | { ok: false, error: OutputError }
	const patterns = expand_patterns(self.include, file_system, project_root)
	const exclusions = expand_patterns(self.exclude, file_system, project_root)
	table.insert(exclusions, output_root)
	table.insert(exclusions, `{output_root}/**/*`)

	const found = file_system:find(patterns, exclusions)
	if not found.ok then
		return {
			ok = false,
			error = {
				code = "filesystem_error",
				message = found.error.message,
				path = found.error.path,
			},
		}
	end
	return { ok = true, files = found.value }
end

const function new(config: OutputConfig): OutputEmitter
	if typeof(config) ~= "table" then
		error("kern: output configuration must be a table", 2)
	end
	if typeof(config.path) ~= "string" then
		error("kern: output path must be a string", 2)
	end
	if config.path == "" then
		error("kern: output path cannot be empty", 2)
	end

	const output_path = path.normalize(config.path)
	const source_root = if config.source_root ~= nil then path.normalize(config.source_root) else nil
	const include = copy_paths("include", config.include or {})
	const exclude = copy_paths("exclude", config.exclude or {})
	validate_relative_path("output path", config.path)
	if source_root ~= nil then
		if source_root == "" then
			error("kern: output source root cannot be empty", 2)
		end
		validate_relative_path("source root", source_root)
	end
	if output_path == "" or output_path == "." or path.is_absolute(output_path) then
		error("kern: output path must be a safe relative directory", 2)
	end
	if source_root ~= nil and #include > 0 then
		error("kern: output accepts either source_root or include, not both", 2)
	end
	if source_root == nil and #include == 0 then
		error("kern: output requires source_root or at least one included path", 2)
	end
	if
		source_root ~= nil
		and (path.is_inside(source_root, output_path) or path.is_inside(output_path, source_root))
	then
		error("kern: output path and source root cannot contain one another", 2)
	end

	return {
		kind = "output",
		name = config.name or "directory",
		path = output_path,
		source_root = source_root,
		include = include,
		exclude = exclude,
		clean = if config.clean == nil then true else config.clean,
		include_packages = if config.include_packages == nil then true else config.include_packages,
		output_path = function(self, source_path, project_root)
			const root = path.join(project_root, self.path)
			const absolute_source = if path.is_inside(project_root, source_path)
				then source_path
				else path.join(project_root, source_path)
			if self.source_root == nil then
				return path.join(root, path.relative(project_root, absolute_source))
			end
			const source_root = path.join(project_root, self.source_root)
			if not path.is_inside(source_root, absolute_source) then
				return path.join(root, path.relative(project_root, absolute_source))
			end
			return path.join(root, path.relative(source_root, absolute_source))
		end,
		emit = function(self, files, file_system, project_root)
			const output_root = path.join(project_root, self.path)
			if not path.is_inside(project_root, output_root) then
				return failure("output_error", "unsafe output path", output_root)
			end
			if self.source_root ~= nil then
				const source_root = path.join(project_root, self.source_root)
				if path.is_inside(project_root, source_root) and path.is_inside(output_root, source_root) then
					return failure("output_error", "unsafe output path", output_root)
				end
			end

			local selected: { [string]: boolean }? = nil
			if #self.include > 0 then
				const selection = select_files(self, file_system, project_root, output_root)
				if not selection.ok then
					return { ok = false, error = selection.error }
				end
				selected = {}
				for _, file_path in selection.files do
					selected[path.normalize(file_path)] = true
				end
			end

			const files_to_write: { BuildFile } = {}
			const included_sources = {}
			for _, file in files do
				const file_path = path.normalize(file.file_path)
				if selected == nil or selected[file_path] then
					table.insert(files_to_write, file)
					included_sources[file_path] = true
				end
			end
			if selected ~= nil then
				for file_path in selected do
					if not included_sources[file_path] then
						const read = file_system:read_file(file_path)
						if not read.ok then
							return failure("filesystem_error", read.error.message, file_path)
						end
						table.insert(files_to_write, { file_path = file_path, source = read.value })
					end
				end
			end
			table.sort(files_to_write, function(left: BuildFile, right: BuildFile)
				return left.file_path < right.file_path
			end)

			const destinations = {}
			for _, file in files_to_write do
				const destination = self:output_path(file.file_path, project_root)
				if not path.is_inside(output_root, destination) then
					return failure("output_error", "output file escapes output root", destination)
				end
				table.insert(destinations, destination)
			end

			if self.clean then
				const removed = file_system:remove_directory(output_root)
				if not removed.ok then
					return failure("filesystem_error", removed.error.message, output_root)
				end
			end

			local files_written = 0
			for index, file in files_to_write do
				const destination = destinations[index]
				const directory = path.directory_name(destination)
				const created = file_system:create_directory(directory)
				if not created.ok then
					return failure("filesystem_error", created.error.message, directory)
				end
				const written = file_system:write_file(destination, file.source)
				if not written.ok then
					return failure("filesystem_error", written.error.message, destination)
				end
				files_written += 1
			end
			return { ok = true, files_written = files_written }
		end,
	}
end

output.new = new
output.directory = new

return output
