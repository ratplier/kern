--!strict

const file_system = require("@std/fs")
const json = require("@std/json")
const luau = require("@std/luau")
const path = require("@std/path")
const process = require("@std/process")

type HostRequire = (request: string) -> unknown

export type EmbeddedRecord = {
	source_path: string,
	source: string,
}

export type EmbeddedPackage = {
	version: string,
	modules: { [string]: EmbeddedRecord },
}

export type EmbeddedTypedefPackage = {
	version: string,
	files: { [string]: EmbeddedRecord },
}

export type SetupResult =
	{
		ok: true,
		path: string,
		changed: boolean,
	}
	| {
		ok: false,
		error: string,
	}

export type LoadResult =
	{
		ok: true,
		value: unknown,
	}
	| {
		ok: false,
		error: string,
	}

type RuntimeState = {
	host_require: HostRequire,
	modules: EmbeddedPackage,
	typedefs: EmbeddedTypedefPackage,
	cache: { [string]: unknown },
	project_cache: { [string]: unknown },
	loading: { [string]: boolean },
	project_root: string,
	project_aliases: { [string]: string },
}

export type Runtime = {
	state: RuntimeState,
	require_public: (self: Runtime, request: string) -> unknown,
	load_project: (self: Runtime, project_path: string) -> LoadResult,
	ensure_typedefs: (self: Runtime, root: string?) -> SetupResult,
}

local runtime = {}

const function normalized(value: string): string
	const replaced = path.format(path.normalize(value)):gsub("\\", "/")
	return replaced
end

const function base_name(value: string): string
	const name = path.basename(value)
	if name == nil then
		error(`kern: path '{value}' has no base name`, 0)
	end

	return name
end

const function module_candidates(value: string): { string }
	const normalized_value = normalized(value)
	const extension = path.extname(normalized_value)
	if extension ~= "" then
		return { normalized_value }
	end

	return {
		normalized_value,
		`{normalized_value}.luau`,
		`{normalized_value}.lua`,
		`{normalized_value}/init.luau`,
		`{normalized_value}/init.lua`,
	}
end

const function embedded_id_for_path(modules: { [string]: EmbeddedRecord }, source_path: string): string?
	const normalized_source_path = normalized(source_path)

	for module_id, record in modules do
		if normalized(record.source_path) == normalized_source_path then
			return module_id
		end
	end

	return nil
end

const function read_file(file_path: string): { ok: true, source: string } | { ok: false, error: string }
	const success, value = pcall(function()
		return file_system.readFileToString(file_path)
	end)
	if not success then
		return { ok = false, error = tostring(value) }
	end

	return { ok = true, source = value }
end

const function load_chunk(source: string, chunk_name: string, environment: { [string]: unknown }): unknown
	const bytecode = luau.compile(source)
	setmetatable(environment, { __index = _G })
	-- TODO(luau): Lute exposes dynamic environments through an any-key table.
	const chunk = luau.load(bytecode, chunk_name, environment :: { [any]: any })
	-- TODO(luau): loaded chunks have an untyped dynamic return value.
	const callable = chunk :: () -> unknown
	return callable()
end

const function runtime_request(request: string): boolean
	return request == "@kern" or request:sub(1, 6) == "@kern/" or request == "@cli" or request:sub(1, 5) == "@cli/"
end

const function project_path_for_request(current_path: string, request: string): { string }
	const directory = path.dirname(current_path)
	return module_candidates(path.format(path.join(directory, request)))
end

const function project_alias_path_for_request(self: Runtime, request: string): { string }?
	const request_name = if request:sub(1, 1) == "@" then request:sub(2) else request
	for alias, target in self.state.project_aliases do
		if request_name == alias or request_name:sub(1, #alias + 1) == `{alias}/` then
			const suffix = request_name:sub(#alias + 1)
			const target_path = path.join(self.state.project_root, `{target}{suffix}`)
			return module_candidates(path.format(target_path))
		end
	end

	return nil
end

const function embedded_path_for_request(self: Runtime, current_path: string, request: string): string?
	for _, candidate in project_path_for_request(current_path, request) do
		const module_id = embedded_id_for_path(self.state.modules.modules, candidate)
		if module_id ~= nil then
			return module_id
		end
	end

	return nil
end

const function load_embedded(self: Runtime, module_id: string): unknown
	const cached = self.state.cache[module_id]
	if cached ~= nil then
		return cached
	end

	if self.state.loading[module_id] then
		error(`kern: embedded module cycle at '{module_id}'`, 0)
	end

	const record = self.state.modules.modules[module_id]
	if record == nil then
		error(`kern: unknown embedded module '{module_id}'`, 0)
	end

	self.state.loading[module_id] = true
	const environment = {
		require = function(request: string): unknown
			if runtime_request(request) or request:sub(1, 2) == "./" or request:sub(1, 3) == "../" then
				return runtime.require_module(self, request, record.source_path, true)
			end

			return self.state.host_require(request)
		end,
	}

	const success, value = pcall(function()
		return load_chunk(record.source, module_id, environment)
	end)
	self.state.loading[module_id] = nil
	if not success then
		error(tostring(value), 0)
	end

	self.state.cache[module_id] = value
	return value
end

function runtime.require_module(self: Runtime, request: string, current_path: string, is_embedded: boolean): unknown
	if runtime_request(request) then
		if self.state.modules.modules[request] == nil then
			error(`kern: unknown runtime module '{request}'`, 0)
		end

		return load_embedded(self, request)
	end

	if request:sub(1, 2) == "./" or request:sub(1, 3) == "../" then
		if is_embedded then
			const module_id = embedded_path_for_request(self, current_path, request)
			if module_id == nil then
				error(`kern: embedded module not found for '{request}'`, 0)
			end

			return load_embedded(self, module_id)
		end

		for _, candidate in project_path_for_request(current_path, request) do
			if file_system.exists(candidate) and file_system.type(candidate) == "file" then
				return runtime.load_project_module(self, candidate)
			end
		end

		error(`kern: project module not found for '{request}'`, 0)
	end

	if not is_embedded then
		const candidates = project_alias_path_for_request(self, request)
		if candidates ~= nil then
			for _, candidate in candidates do
				if file_system.exists(candidate) and file_system.type(candidate) == "file" then
					return runtime.load_project_module(self, candidate)
				end
			end

			error(`kern: project alias did not resolve '{request}'`, 0)
		end
	end

	return self.state.host_require(request)
end

function runtime.load_project_module(self: Runtime, file_path: string): unknown
	const normalized_file_path = normalized(file_path)
	const cached = self.state.project_cache[normalized_file_path]
	if cached ~= nil then
		return cached
	end

	const source_result = read_file(normalized_file_path)
	if not source_result.ok then
		error(source_result.error, 0)
	end

	const environment = {
		require = function(request: string): unknown
			return runtime.require_module(self, request, normalized_file_path, false)
		end,
	}
	const value = load_chunk(source_result.source, normalized_file_path, environment)
	self.state.project_cache[normalized_file_path] = value
	return value
end

function runtime.load_project(self: Runtime, project_path: string): LoadResult
	const success, value = pcall(function()
		const normalized_project_path = normalized(project_path)
		self.state.project_root = path.dirname(normalized_project_path)
		if self.state.project_root == "" then
			self.state.project_root = "."
		end
		self.state.project_aliases = runtime.read_project_aliases(self, self.state.project_root)
		return runtime.load_project_module(self, project_path)
	end)
	if not success then
		return { ok = false, error = tostring(value) }
	end

	return { ok = true, value = value }
end

function runtime.read_project_aliases(self: Runtime, project_root: string): { [string]: string }
	const config_path = path.format(path.join(project_root, ".luaurc"))
	if not file_system.exists(config_path) then
		return {}
	end

	const source = file_system.readFileToString(config_path)
	const value = json.deserialize(source)
	if typeof(value) ~= "table" then
		return {}
	end

	-- TODO(luau): JSON objects are dynamically typed by the standard library.
	const object = value :: { [string]: unknown }
	const aliases = object.aliases
	if typeof(aliases) ~= "table" then
		return {}
	end

	-- TODO(luau): JSON alias values require runtime string validation.
	const alias_object = aliases :: { [string]: unknown }
	const result: { [string]: string } = {}
	for alias, target in alias_object do
		if typeof(target) == "string" then
			result[alias] = target
		end
	end

	return result
end

function runtime.require_public(self: Runtime, request: string): unknown
	return runtime.require_module(self, request, "", false)
end

const function typedef_path(root: string, version: string): string
	const value = path.format(path.join(root, ".kern", "typedefs", version, "kern"))
	return tostring(value)
end

const function typedef_relative_path(source_path: string): string
	const normalized_path = normalized(source_path)
	if normalized_path == "types/.luaurc" then
		return "../.luaurc"
	end
	const prefix = "types/kern/"
	local relative_path: string
	if normalized_path:sub(1, #prefix) == prefix then
		relative_path = normalized_path:sub(#prefix + 1)
	else
		relative_path = base_name(normalized_path)
	end

	return relative_path
end

const function all_typedefs_match(directory: string, package: EmbeddedTypedefPackage): boolean
	for _, record in package.files do
		const file_path = path.format(path.join(directory, typedef_relative_path(record.source_path)))
		if
			not file_system.exists(file_path)
			or file_system.type(file_path) ~= "file"
			or file_system.readFileToString(file_path) ~= record.source
		then
			return false
		end
	end

	return true
end

const function write_typedefs(directory: string, package: EmbeddedTypedefPackage)
	for _, record in package.files do
		const file_path = path.format(path.join(directory, typedef_relative_path(record.source_path)))
		file_system.createDirectory(path.dirname(file_path), { makeParents = true })
		file_system.writeStringToFile(file_path, record.source)
	end
end

function runtime.ensure_typedefs(self: Runtime, root: string?): SetupResult
	const destination_root = if root ~= nil then root else tostring(process.homedir())
	const directory = typedef_path(destination_root, self.state.typedefs.version)
	if all_typedefs_match(directory, self.state.typedefs) then
		return { ok = true, path = directory, changed = false }
	end

	const temporary_directory = `{directory}.tmp`
	local has_started_target = false
	const success, error_message = pcall(function()
		if file_system.exists(temporary_directory) then
			file_system.removeDirectory(temporary_directory, { recursive = true })
		end

		write_typedefs(temporary_directory, self.state.typedefs)
		if file_system.exists(directory) then
			file_system.removeDirectory(directory, { recursive = true })
		end

		has_started_target = true
		write_typedefs(directory, self.state.typedefs)
		file_system.removeDirectory(temporary_directory, { recursive = true })
	end)
	if not success then
		if file_system.exists(temporary_directory) then
			file_system.removeDirectory(temporary_directory, { recursive = true })
		end
		if has_started_target and file_system.exists(directory) then
			file_system.removeDirectory(directory, { recursive = true })
		end
		return { ok = false, error = tostring(error_message) }
	end

	return { ok = true, path = directory, changed = true }
end

function runtime.new(host_require: HostRequire, modules: EmbeddedPackage, typedefs: EmbeddedTypedefPackage): Runtime
	if modules.version ~= typedefs.version then
		error(
			`kern: embedded runtime version '{modules.version}' does not match typedef version '{typedefs.version}'`,
			2
		)
	end

	return {
		state = {
			host_require = host_require,
			modules = modules,
			typedefs = typedefs,
			cache = {},
			project_cache = {},
			loading = {},
			project_root = ".",
			project_aliases = {},
		},
		require_public = runtime.require_public,
		load_project = runtime.load_project,
		ensure_typedefs = runtime.ensure_typedefs,
	}
end

return runtime
