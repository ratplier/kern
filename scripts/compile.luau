--!strict

const file_system = require("@std/fs")
const path = require("@std/path")
const process = require("@std/process")

const function default_output_path(): string
	return path.format(path.join("bin", "build"))
end

const function output_path(): string
	return process.args[2] or default_output_path()
end

const function create_output_directory(value: string)
	const directory = path.dirname(value)
	if not file_system.exists(directory) then
		file_system.createDirectory(directory, { makeParents = true })
	end
end

const function remove_existing_binary(value: string)
	if not file_system.exists(value) then
		return
	end
	if file_system.type(value) ~= "file" then
		error(`kern: compile output '{value}' is not a file`)
	end
	file_system.remove(value)
end

const function compile(value: string): number
	const result = process.run({
		"lute",
		"compile",
		"src/cli/run.luau",
		"--output",
		value,
	}, { stdio = "inherit" })

	return result.exitcode
end

const function run_generator(script: string): number
	const result = process.run({ "lute", "run", script }, { stdio = "inherit" })
	return result.exitcode
end

const output = output_path()
for _, script in { "scripts/generate_modules.luau", "scripts/generate_types.luau" } do
	const exit_code = run_generator(script)
	if exit_code ~= 0 then
		process.exit(exit_code)
	end
end
create_output_directory(output)
remove_existing_binary(output)
process.exit(compile(output))
