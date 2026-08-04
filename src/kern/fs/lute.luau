--!strict

const types = require("@kern/fs/types")
const path = require("@kern/core/path")
const fs = require("@std/fs")

const function failure<T>(message: string, file_path: string?): types.OperationResult<T>
	return {
		ok = false,
		error = {
			code = "filesystem_error",
			message = message,
			path = file_path,
		},
	}
end

const function protected<T>(callback: () -> T, file_path: string?): types.OperationResult<T>
	const success, value = pcall(callback)
	if not success then
		return failure(tostring(value), file_path)
	end

	return { ok = true, value = value }
end

const function glob_to_pattern(glob: string): string
	local escaped = path.normalize(glob):gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1")
	escaped = escaped:gsub("%*%*/", "\1")
	escaped = escaped:gsub("%*%*", "\2")
	escaped = escaped:gsub("%*", "[^/]*")
	escaped = escaped:gsub("\1", ".*")
	escaped = escaped:gsub("\2", ".*")

	return `^{escaped}$`
end

const function matches(file_path: string, patterns: { string }): boolean
	for _, pattern in patterns do
		const normalized_pattern = path.normalize(pattern)
		if
			normalized_pattern:sub(1, 3) == "**/"
			and matches(path.base_name(file_path), { normalized_pattern:sub(4) })
		then
			return true
		end
		if file_path:match(glob_to_pattern(pattern)) ~= nil then
			return true
		end
	end

	return false
end

const function list_files(directory: string, output: { string })
	for _, entry in fs.listDirectory(directory) do
		const entry_path = path.join(directory, entry.name)

		if entry.type == "dir" then
			list_files(entry_path, output)
		else
			table.insert(output, entry_path)
		end
	end

	return output
end

local lute_fs = {}

function lute_fs.is_file(_self: types.Filesystem, file_path: string): boolean
	return fs.exists(file_path) and fs.type(file_path) == "file"
end

function lute_fs.is_directory(_self: types.Filesystem, directory_path: string): boolean
	return fs.exists(directory_path) and fs.type(directory_path) == "dir"
end

function lute_fs.read_file(_self: types.Filesystem, file_path: string): types.OperationResult<string>
	return protected(function()
		return fs.readFileToString(file_path)
	end, file_path)
end

function lute_fs.write_file(_self: types.Filesystem, file_path: string, source: string): types.OperationResult<nil>
	return protected(function()
		fs.writeStringToFile(file_path, source)
		return nil
	end, file_path)
end

function lute_fs.create_directory(_self: types.Filesystem, directory_path: string): types.OperationResult<nil>
	return protected(function()
		fs.createDirectory(directory_path, { makeParents = true })
		return nil
	end, directory_path)
end

function lute_fs.remove_directory(_self: types.Filesystem, directory_path: string): types.OperationResult<nil>
	return protected(function()
		fs.removeDirectory(directory_path, { recursive = true })
		return nil
	end, directory_path)
end

function lute_fs.find(
	_self: types.Filesystem,
	patterns: { string },
	exclusions: { string }
): types.OperationResult<{ string }>
	return protected(function()
		const files = list_files(".", {})

		const found = {}

		for _, file_path in files do
			const normalized = path.normalize(file_path)

			if matches(normalized, patterns) and not matches(normalized, exclusions) then
				table.insert(found, normalized)
			end
		end

		table.sort(found)
		return found
	end, nil)
end

return lute_fs
