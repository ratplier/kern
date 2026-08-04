--!strict

const types = require("@kern/fs/types")
const path = require("@kern/core/path")

type MemoryData = {
	files: { [string]: string },
	directories: { [string]: boolean },
}

type MemoryFilesystem = MemoryData & {
	is_file: (self: MemoryFilesystem, file_path: string) -> boolean,
	is_directory: (self: MemoryFilesystem, directory_path: string) -> boolean,
	read_file: (self: MemoryFilesystem, file_path: string) -> types.OperationResult<string>,
	write_file: (self: MemoryFilesystem, file_path: string, source: string) -> types.OperationResult<nil>,
	create_directory: (self: MemoryFilesystem, directory_path: string) -> types.OperationResult<nil>,
	remove_directory: (self: MemoryFilesystem, directory_path: string) -> types.OperationResult<nil>,
	find: (
		self: MemoryFilesystem,
		patterns: { string },
		exclusions: { string }
	) -> types.OperationResult<{ string }>,
}

local memory = {}
local memory_file_system = {}

const function glob_to_pattern(glob: string): string
	local escaped = path.normalize(glob):gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1")
	escaped = escaped:gsub("%*%*/", "\1")
	escaped = escaped:gsub("%*%*", "\2")
	escaped = escaped:gsub("%*", "[^/]*")
	escaped = escaped:gsub("\1", ".*")
	escaped = escaped:gsub("\2", ".*")

	return `^{escaped}$`
end

const function matches(value: string, patterns: { string }): boolean
	for _, pattern in patterns do
		const normalized_pattern = path.normalize(pattern)
		if normalized_pattern:sub(1, 3) == "**/" and matches(path.base_name(value), { normalized_pattern:sub(4) }) then
			return true
		end
		if value:match(glob_to_pattern(pattern)) ~= nil then
			return true
		end
	end

	return false
end

const function create_directory_data(self: MemoryData, directory_path: string)
	const normalized = path.normalize(directory_path)
	local current = ""

	for segment in normalized:gmatch("[^/]+") do
		current = if current == "" then segment else `{current}/{segment}`
		self.directories[current] = true
	end
end

const function add_file(self: MemoryData, file_path: string, source: string)
	const normalized = path.normalize(file_path)
	const directory = path.directory_name(normalized)

	if directory ~= "" and not self.directories[directory] then
		create_directory_data(self, directory)
	end

	self.files[normalized] = source
end

const function new(initial_files: { [string]: string }?): MemoryFilesystem
	const data = {
		files = {},
		directories = { [""] = true },
	}

	for file_path, source in initial_files or {} do
		add_file(data, file_path, source)
	end

	return {
		files = data.files,
		directories = data.directories,
		is_file = memory_file_system.is_file,
		is_directory = memory_file_system.is_directory,
		read_file = memory_file_system.read_file,
		write_file = memory_file_system.write_file,
		create_directory = memory_file_system.create_directory,
		remove_directory = memory_file_system.remove_directory,
		find = memory_file_system.find,
	}
end

memory.new = new

function memory_file_system.is_file(self: MemoryFilesystem, file_path: string): boolean
	return self.files[path.normalize(file_path)] ~= nil
end

function memory_file_system.is_directory(self: MemoryFilesystem, directory_path: string): boolean
	const normalized = path.normalize(directory_path)

	return self.directories[normalized] == true or self.directories[`{normalized}/`] == true
end

function memory_file_system.read_file(self: MemoryFilesystem, file_path: string): types.OperationResult<string>
	const normalized = path.normalize(file_path)
	const source = self.files[normalized]

	if source == nil then
		return {
			ok = false,
			error = {
				code = "filesystem_error",
				message = "file does not exist",
				path = normalized,
			},
		}
	end

	return {
		ok = true,
		value = source,
	}
end

function memory_file_system.write_file(
	self: MemoryFilesystem,
	file_path: string,
	source: string
): types.OperationResult<nil>
	add_file(self, file_path, source)

	return {
		ok = true,
		value = nil,
	}
end

function memory_file_system.create_directory(self: MemoryFilesystem, directory_path: string): types.OperationResult<nil>
	create_directory_data(self, directory_path)

	return {
		ok = true,
		value = nil,
	}
end

function memory_file_system.remove_directory(self: MemoryFilesystem, directory_path: string): types.OperationResult<nil>
	const normalized = path.normalize(directory_path)

	for file_path in self.files do
		if path.is_inside(normalized, file_path) then
			self.files[file_path] = nil
		end
	end

	for existing in self.directories do
		if path.is_inside(normalized, existing) then
			self.directories[existing] = nil
		end
	end

	return {
		ok = true,
		value = nil,
	}
end

function memory_file_system.find(
	self: MemoryFilesystem,
	patterns: { string },
	exclusions: { string }
): types.OperationResult<{ string }>
	const found = {}

	for file_path in self.files do
		if matches(file_path, patterns) and not matches(file_path, exclusions) then
			table.insert(found, file_path)
		end
	end

	table.sort(found)

	return {
		ok = true,
		value = found,
	}
end

return memory
