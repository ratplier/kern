--!strict

const kern = require("@kern")
const memory = require("@kern/fs/memory")

local helpers = {}

function helpers.file_system(files: { [string]: string }): any
	return memory.new(files)
end

function helpers.project(
	files: { [string]: string },
	components: { any },
	entries: { string },
	include: { string }?
): any
	return kern.project({
		root = ".",
		entries = entries,
		include = include or { "src/**/*.luau", "src/*.luau" },
		components = components,
		file_system = helpers.file_system(files),
	})
end

function helpers.source(result: any, file_path: string): string?
	for _, file in result.files do
		if file.file_path == file_path then
			return file.source
		end
	end
	return nil
end

return helpers
