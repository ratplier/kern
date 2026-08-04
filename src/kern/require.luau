--!strict

const path = require("@kern/core/path")
const result = require("@kern/core/result")
const file_system_types = require("@kern/fs/types")
const calls = require("@kern/query/builtins/calls")
const location = require("@kern/syntax/location")
const parse = require("@kern/syntax/parse")

export type RequireRewriteMode = "relative"

export type RequireConfig = {
	name: string?,
	aliases: { [string]: string },
	extensions: { string }?,
	index_names: { string }?,
	rewrite: RequireRewriteMode?,
	allow_relative: boolean?,
	allow_unaliased: boolean?,
}

export type RequireErrorCode =
	"parse_error"
	| "missing_module"
	| "ambiguous_module"
	| "unknown_alias"
	| "path_escape"
	| "unsupported_require"

export type RequireError = {
	code: RequireErrorCode,
	message: string,
	source_path: string?,
	request: string?,
}

export type ResolvedRequire = {
	request: string,
	source_path: string,
	resolved_path: string,
	output_path: string?,
	alias: string?,
	span: { start: number, finish: number },
	argument_span: { start: number, finish: number },
}

export type RequireRequest = {
	request: string,
	span: { start: number, finish: number },
	argument_span: { start: number, finish: number },
}

export type RequireResolver = {
	kind: "require",
	name: string,
	aliases: { [string]: string },
	extensions: { string },
	index_names: { string },
	allow_relative: boolean,
	allow_unaliased: boolean,
	resolve: (
		self: RequireResolver,
		source_path: string,
		request: string,
		file_system: file_system_types.Filesystem,
		project_root: string
	) -> result.Result<string, RequireError>,
	rewrite: (self: RequireResolver, source_path: string, destination_path: string, request: string) -> string,
}

local resolver = {}

const function validate_alias(alias: string, target: string)
	if typeof(alias) ~= "string" then
		error("kern: require alias names must be strings", 2)
	end
	if typeof(target) ~= "string" then
		error(`kern: target for require alias '{alias}' must be a string`, 2)
	end
	if alias:sub(1, 1) ~= "@" or alias:find("/", 1, true) ~= nil or alias:find("\\", 1, true) ~= nil or #alias < 2 then
		error(`kern: invalid require alias '{alias}'`, 2)
	end
	const normalized = path.normalize(target)
	if normalized == "" or path.is_absolute(target) or normalized == ".." or normalized:sub(1, 3) == "../" then
		error(`kern: require alias '{alias}' has an empty target`, 2)
	end
end

const function copy_extensions(values: { string }): { string }
	if #values == 0 then
		error("kern: require extensions cannot be empty", 2)
	end

	const copied = {}
	for _, value in values do
		if value == "" or value:sub(1, 1) ~= "." then
			error(`kern: invalid require extension '{value}'`, 2)
		end
		table.insert(copied, value)
	end
	return copied
end

const function copy_index_names(values: { string }): { string }
	if #values == 0 then
		error("kern: require index names cannot be empty", 2)
	end

	const copied = {}
	for _, value in values do
		if value == "" or value:find("/", 1, true) ~= nil then
			error(`kern: invalid require index name '{value}'`, 2)
		end
		table.insert(copied, value)
	end
	return copied
end

const function candidates(base: string, extensions: { string }, index_names: { string }): { string }
	const extension = path.extension(base)
	if extension ~= "" then
		return { base }
	end

	const output = { base }
	for _, suffix in extensions do
		table.insert(output, `{base}{suffix}`)
	end
	for _, index_name in index_names do
		for _, suffix in extensions do
			table.insert(output, path.join(base, `{index_name}{suffix}`))
		end
	end
	return output
end

const function requests(source: string): { RequireRequest }
	const output = {}
	local cursor = 1
	const pattern = 'require%s*%(%s*([%"])(.-)%1%s*%)'

	while cursor <= #source do
		const start, finish, quote, request = source:find(pattern, cursor)
		if start == nil or finish == nil or quote == nil or request == nil then
			break
		end

		const preceding = source:sub(start - 1, start - 1)
		if preceding == "." or preceding == ":" then
			cursor = finish + 1
			continue
		end

		const quote_start = source:find(quote, start, true)
		if quote_start ~= nil then
			table.insert(output, {
				request = request,
				span = { start = start - 1, finish = finish },
				argument_span = {
					start = quote_start,
					finish = quote_start + #request,
				},
			})
		end
		cursor = finish + 1
	end

	return output
end

const function scan(source: string): result.Result<{ RequireRequest }, RequireError>
	const parsed = parse.source(source)
	if not parsed.ok then
		return {
			ok = false,
			error = {
				code = "parse_error",
				message = parsed.error.message,
				source_path = parsed.error.file_path,
				request = nil,
			},
		}
	end

	const found = requests(source)
	const requests_by_start: { [number]: RequireRequest } = {}
	for _, request in found do
		requests_by_start[request.span.start] = request
	end

	const output = {}
	for _, call in calls.any:collect(parsed.tree.root) do
		if call.callee ~= "require" then
			continue
		end
		const call_start =
			location.offset_from_line_column(source, call.raw.location.beginLine, call.raw.location.beginColumn)
		const request = requests_by_start[call_start]
		if not call.is_global or request == nil then
			return {
				ok = false,
				error = {
					code = "unsupported_require",
					message = "require call must use one string argument",
					source_path = nil,
					request = nil,
				},
			}
		end

		table.insert(output, request)
	end
	return { ok = true, value = output }
end

const function failure(
	code: RequireErrorCode,
	message: string,
	source_path: string,
	request: string
): result.Result<string, RequireError>
	return {
		ok = false,
		error = {
			code = code,
			message = message,
			source_path = source_path,
			request = request,
		},
	}
end

const function new(config: RequireConfig): RequireResolver
	if typeof(config) ~= "table" then
		error("kern: require configuration must be a table", 2)
	end
	if typeof(config.aliases) ~= "table" then
		error("kern: require aliases must be a table", 2)
	end
	if config.name ~= nil and config.name == "" then
		error("kern: require resolver name cannot be empty", 2)
	end
	if config.rewrite ~= nil and config.rewrite ~= "relative" then
		error(`kern: unsupported require rewrite mode '{config.rewrite}'`, 2)
	end

	const aliases = {}
	for alias, target in config.aliases do
		validate_alias(alias, target)
		aliases[alias] = path.normalize(target)
	end

	return {
		kind = "require",
		name = config.name or "require",
		aliases = aliases,
		extensions = copy_extensions(config.extensions or { ".luau", ".lua" }),
		index_names = copy_index_names(config.index_names or { "init", "index" }),
		allow_relative = if config.allow_relative == nil then true else config.allow_relative,
		allow_unaliased = config.allow_unaliased or false,
		resolve = function(self, source_path, request, file_system, project_root)
			local base: string?
			if path.is_relative_request(request) then
				if not self.allow_relative then
					return failure("unknown_alias", "relative requires are disabled", source_path, request)
				end
				base = path.join(path.directory_name(source_path), request)
			elseif request:sub(1, 1) == "@" then
				const slash = request:find("/", 2, true)
				const alias = if slash == nil then request else request:sub(1, slash - 1)
				const target = self.aliases[alias]
				if target == nil then
					return failure("unknown_alias", `unknown require alias '{alias}'`, source_path, request)
				end
				const suffix = if slash == nil then "" else request:sub(slash + 1)
				base = path.join(project_root, target, suffix)
			elseif self.allow_unaliased then
				base = path.join(project_root, request)
			else
				return failure("unknown_alias", `unaliased require '{request}' is disabled`, source_path, request)
			end

			if base == nil or not path.is_inside(project_root, base) then
				return failure("path_escape", `require '{request}' escapes the project root`, source_path, request)
			end

			const found = {}
			for _, candidate in candidates(base, self.extensions, self.index_names) do
				if file_system:is_file(candidate) then
					table.insert(found, candidate)
				end
			end
			if #found == 0 then
				return failure("missing_module", `module '{request}' was not found`, source_path, request)
			end
			if #found > 1 then
				return failure("ambiguous_module", `module '{request}' has multiple candidates`, source_path, request)
			end
			return { ok = true, value = found[1] }
		end,
		rewrite = function(self, source_path, destination_path, _request)
			const destination = path.remove_extension(destination_path, self.extensions)
			local collapsed = destination
			for _, index_name in self.index_names do
				if path.base_name(destination) == index_name then
					collapsed = path.directory_name(destination)
					break
				end
			end
			local relative = path.relative(path.directory_name(source_path), collapsed)
			if relative == "" then
				relative = path.base_name(collapsed)
			end
			if relative:sub(1, 1) ~= "." then
				relative = `./{relative}`
			end
			return relative
		end,
	}
end

resolver.new = new
resolver.candidates = candidates
resolver.requests = requests
resolver.scan = scan

return resolver
