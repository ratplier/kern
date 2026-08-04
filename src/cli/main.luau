--!strict

const runtime_module = require("./runtime")
const modules = require("./gen/modules")
const typedefs = require("./gen/types")
const file_system = require("@std/fs")
const json = require("@std/json")
const path = require("@std/path")
const process = require("@std/process")

type LauncherArguments = {
	project_path: string?,
	command_arguments: { string },
}

type ParseArguments = {
	command: string,
	fix: boolean,
	check: boolean,
	paths: { string },
}

type ParseResult =
	{
		ok: true,
		value: ParseArguments,
	}
	| {
		ok: false,
		error: string,
	}

type Project = {
	kind: "project",
}

type RunResult = {
	ok: boolean,
	exit_code: number,
}

type KernCli = {
	parse: (values: { string }) -> ParseResult,
	run: (project: Project, values: ParseArguments) -> RunResult,
	render: (value: RunResult) -> string,
	exit_code: (value: RunResult) -> number,
	usage: () -> string,
}

const PROJECT_FILE = "default.kern.luau"
const PROJECT_TEMPLATE = [[local kern = require("@kern")

return kern.project({
	root = ".",
	entries = { "src/init.luau" },
	include = { "src/**/*.luau", "src/*.luau" },
	components = {
		kern.output.directory({
			path = "build",
			source_root = "src",
		}),
	},
})
]]
const ENTRY_TEMPLATE = [[--!strict

-- Kern processes this file during `kern check` and writes it to build/ during `kern build`.
print("Hello from Kern")
]]

const function command_arguments(values: { string }): { string }
	const arguments = {}
	for index = 2, #values do
		table.insert(arguments, values[index])
	end

	return arguments
end

const function split_arguments(values: { string }): LauncherArguments
	local project_path: string? = nil
	const command_values: { string } = {}
	local index = 1

	while index <= #values do
		const value = values[index]

		if value == "--project" or value == "-p" then
			index += 1
			const next_value = values[index]
			if next_value == nil then
				error("kern: --project requires a path", 0)
			end

			project_path = next_value
		elseif value:sub(1, 10) == "--project=" then
			project_path = value:sub(11)
			if project_path == "" then
				error("kern: --project requires a path", 0)
			end
		else
			table.insert(command_values, value)
		end

		index += 1
	end

	return {
		project_path = project_path,
		command_arguments = command_values,
	}
end

const function find_default_project(): string?
	local directory = path.format(path.normalize(process.cwd()))
	while true do
		const candidate = path.format(path.join(directory, PROJECT_FILE))
		if file_system.exists(candidate) and file_system.type(candidate) == "file" then
			return candidate
		end

		const parent = path.format(path.dirname(directory))
		if parent == directory or parent == "" then
			return nil
		end
		directory = parent
	end
end

const function has_help(values: { string }): boolean
	for _, value in values do
		if value == "-h" or value == "--help" then
			return true
		end
	end

	return false
end

const function typedef_root(): string?
	return process.env["KERN_HOME"]
end

const function aliases_for(document: json.Object): json.Object
	const aliases = json.asObject(document["aliases"])
	if aliases ~= nil then
		return aliases
	end

	const created = json.object({})
	document["aliases"] = created
	return created
end

const function luaurc_alias_path(typedef_directory: string): string
	const home_directory = tostring(process.homedir())
	if typedef_directory:sub(1, #home_directory) == home_directory then
		return `~{typedef_directory:sub(#home_directory + 1)}`
	end
	return typedef_directory
end

const function update_luaurc(typedef_directory: string): boolean
	const file_path = path.format(path.join(process.cwd(), ".luaurc"))
	local document = json.object({})
	if file_system.exists(file_path) then
		const source = file_system.readFileToString(file_path)
		const decoded = json.deserialize(source)
		const existing = json.asObject(decoded)
		if existing == nil then
			print(`kern: .luaurc at '{file_path}' must contain a JSON object`)
			return false
		end
		document = existing
	end

	const aliases = aliases_for(document)
	aliases["kern"] = luaurc_alias_path(typedef_directory)
	file_system.writeStringToFile(file_path, `{json.serialize(document, true)}\n`)
	print(`kern: configured '{file_path}'`)
	return true
end

const function setup(runtime_instance: runtime_module.Runtime, values: { string }): number
	if #values == 2 and (values[2] == "-h" or values[2] == "--help") then
		print("usage: kern setup")
		return 0
	elseif #values > 1 then
		print("kern: setup does not accept arguments")
		return 3
	end

	const result = runtime_instance:ensure_typedefs(typedef_root())
	if not result.ok then
		print(`kern: could not install typedefs: {result.error}`)
		return 4
	end

	print(`kern: typedefs at {result.path}`)
	return 0
end

const function init_project(runtime_instance: runtime_module.Runtime, values: { string }): number
	if #values == 2 and (values[2] == "-h" or values[2] == "--help") then
		print("usage: kern init")
		return 0
	elseif #values > 1 then
		print("kern: init does not accept arguments")
		return 3
	end

	const project_path = path.format(path.join(process.cwd(), PROJECT_FILE))
	if file_system.exists(project_path) then
		print(`kern: project already exists at '{project_path}'`)
		return 4
	end

	const result = runtime_instance:ensure_typedefs(typedef_root())
	if not result.ok then
		print(`kern: could not install typedefs: {result.error}`)
		return 4
	end
	if not update_luaurc(result.path) then
		return 4
	end

	const source_directory = path.format(path.join(process.cwd(), "src"))
	const entry_path = path.format(path.join(source_directory, "init.luau"))
	file_system.createDirectory(source_directory, { makeParents = true })
	if not file_system.exists(entry_path) then
		file_system.writeStringToFile(entry_path, ENTRY_TEMPLATE)
		print(`kern: created '{entry_path}'`)
	end
	file_system.writeStringToFile(project_path, PROJECT_TEMPLATE)
	print(`kern: created '{project_path}'`)
	return 0
end

const function load_cli(runtime_instance: runtime_module.Runtime): KernCli
	const value = runtime_instance:require_public("@cli")
	if typeof(value) ~= "table" or typeof(value.parse) ~= "function" then
		error("kern: embedded @cli module is incomplete", 0)
	end

	-- TODO(luau): embedded module values are dynamic by design.
	return value :: KernCli
end

const function main(values: { string }): number
	const runtime_modules = modules :: runtime_module.EmbeddedPackage
	const runtime_typedefs = typedefs :: runtime_module.EmbeddedTypedefPackage

	-- TODO(luau): the host require function is provided by the Lute runtime.
	const host_require = require :: (request: string) -> unknown
	const runtime_instance = runtime_module.new(host_require, runtime_modules, runtime_typedefs)
	const arguments = command_arguments(values)

	if #arguments == 0 or arguments[1] == "-h" or arguments[1] == "--help" then
		print(load_cli(runtime_instance).usage())
		return 0
	end
	if arguments[1] == "--version" then
		print(runtime_modules.version)
		return 0
	end
	if arguments[1] == "setup" then
		return setup(runtime_instance, arguments)
	end
	if arguments[1] == "init" then
		return init_project(runtime_instance, arguments)
	end

	const launcher_arguments = split_arguments(arguments)
	const project_path = launcher_arguments.project_path or find_default_project()
	if project_path == nil then
		print(`kern: could not find '{PROJECT_FILE}' in the current directory or any parent directory`)
		return 3
	end
	const cli = load_cli(runtime_instance)
	const parsed = cli.parse(launcher_arguments.command_arguments)
	if not parsed.ok then
		print(parsed.error)
		return if has_help(launcher_arguments.command_arguments) then 0 else 3
	end

	const project_result = runtime_instance:load_project(project_path)
	if not project_result.ok then
		print(`kern: could not evaluate project: {project_result.error}`)
		return 3
	end
	if typeof(project_result.value) ~= "table" or project_result.value.kind ~= "project" then
		print(`kern: project '{project_path}' did not return a project`)
		return 3
	end

	-- TODO(luau): project configuration values are loaded dynamically.
	const project = project_result.value :: Project
	const result = cli.run(project, parsed.value)
	const message = cli.render(result)
	if message ~= "" then
		print(message)
	end

	return cli.exit_code(result)
end

return main
