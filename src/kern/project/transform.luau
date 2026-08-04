--!strict

const errors = require("@kern/core/errors")
const parse = require("@kern/syntax/parse")
const replacement = require("@kern/syntax/replacement")
const require_resolver = require("@kern/require")
const file_system_types = require("@kern/fs/types")
const scope = require("@kern/scope")
const path = require("@kern/core/path")
const transform_context = require("@kern/transform/context")

const transform_types = require("@kern/transform")
const project_types = require("@kern/project/types")

local transform = {}

const function create_error(
	code: errors.ProcessingErrorCode,
	message: string,
	file_path: string?
): errors.ProcessingError
	return {
		code = code,
		message = message,
		file_path = file_path,
		notes = {},
	}
end

const function resolve_requests(
	source_path: string,
	source: string,
	resolver: require_resolver.RequireResolver,
	file_system: file_system_types.Filesystem,
	project_root: string
): { ok: true, value: { require_resolver.ResolvedRequire } } | { ok: false, error: require_resolver.RequireError }
	const scanned = require_resolver.scan(source)
	if not scanned.ok then
		return { ok = false, error = scanned.error }
	end

	const resolved_requests = {}
	for _, request in scanned.value do
		const resolved = resolver:resolve(source_path, request.request, file_system, project_root)
		if not resolved.ok then
			return { ok = false, error = resolved.error }
		end
		table.insert(resolved_requests, {
			request = request.request,
			source_path = source_path,
			resolved_path = resolved.value,
			output_path = nil,
			alias = if request.request:sub(1, 1) == "@" then request.request:match("^(@[^/]+)") else nil,
			span = request.span,
			argument_span = request.argument_span,
		})
	end
	return { ok = true, value = resolved_requests }
end

const function run(self: project_types.Project, options: project_types.TransformOptions?): project_types.TransformResult
	const start_time = os.clock()
	const function elapsed(): number
		return (os.clock() - start_time) * 1000
	end
	const output = {}
	const diagnostics = {}
	const processing_errors: { errors.ProcessingError } = {}
	const resolver = self.config.require_resolver or require_resolver.new({ aliases = {} })
	local files_processed = 0
	local files_changed = 0
	local files_written = 0
	local file_paths: { string }
	if options ~= nil and options.paths ~= nil then
		file_paths = table.clone(options.paths)
		for index, file_path in file_paths do
			const normalized = path.normalize(file_path)
			file_paths[index] = if path.is_inside(self.config.root, normalized)
				then normalized
				else path.join(self.config.root, normalized)
		end
	else
		const found = self.config.file_system:find(self.config.include, self.config.exclude)

		if not found.ok then
			table.insert(processing_errors, create_error("filesystem_error", found.error.message, found.error.path))
			return {
				ok = false,
				files_processed = 0,
				files_changed = 0,
				files_written = 0,
				files = output,
				diagnostics = diagnostics,
				errors = processing_errors,
				duration_milliseconds = elapsed(),
			}
		end
		file_paths = found.value
	end

	for _, file_path in file_paths do
		local source: string
		if options ~= nil and options.sources ~= nil and options.sources[file_path] ~= nil then
			source = options.sources[file_path]
		else
			const source_result = self.config.file_system:read_file(file_path)
			if not source_result.ok then
				table.insert(
					processing_errors,
					create_error("filesystem_error", source_result.error.message, file_path)
				)
				continue
			end
			source = source_result.value
		end

		files_processed += 1
		const original_source = source
		local parsed = parse.source(source, file_path)
		if not parsed.ok then
			table.insert(processing_errors, create_error("parse_error", parsed.error.message, file_path))
			continue
		end

		const phases: { transform_types.TransformPhase } = if options ~= nil and options.phases ~= nil
			then options.phases
			else { "syntax", "module", "finalize" }
		const should_rewrite_requires = options == nil or options.phases == nil and options.rewrite_requires ~= false
		local resolved_requires = if options ~= nil and options.resolved_requires ~= nil
			then options.resolved_requires[file_path]
			else nil
		for _, phase in phases do
			if phase == "module" and should_rewrite_requires then
				const resolved =
					resolve_requests(file_path, source, resolver, self.config.file_system, self.config.root)
				if not resolved.ok then
					table.insert(
						processing_errors,
						create_error(resolved.error.code, resolved.error.message, file_path)
					)
					break
				end
				resolved_requires = resolved.value
				const require_replacements: { replacement.Replacement } = {}
				for _, request in resolved.value do
					const require_replacement: replacement.Replacement = {
						owner_kind = "require",
						owner_name = resolver.name,
						span = request.argument_span,
						source = resolver:rewrite(file_path, request.resolved_path, request.request),
					}
					table.insert(require_replacements, require_replacement)
				end
				const rewritten = replacement.apply(source, require_replacements)
				if not rewritten.ok then
					table.insert(
						processing_errors,
						create_error("replacement_conflict", rewritten.error.message, file_path)
					)
					break
				end
				if rewritten.source ~= source then
					source = rewritten.source
					const reparsed = parse.source(source, file_path)
					if not reparsed.ok then
						table.insert(processing_errors, create_error("parse_error", reparsed.error.message, file_path))
						break
					end
					parsed = reparsed
				end
			end

			const replacements = {}
			const phase_rules = if phase == "syntax"
				then self.config.transform_rules.syntax
				elseif phase == "module" then self.config.transform_rules.module
				else self.config.transform_rules.finalize
			for _, rule in phase_rules do
				local scope_map = nil
				if rule.scope ~= nil then
					const parsed_scope = scope.parse(source, rule.scope)
					if not parsed_scope.ok then
						table.insert(
							processing_errors,
							create_error("scope_error", parsed_scope.error.message, file_path)
						)
						continue
					end
					scope_map = parsed_scope.value
				end

				const context = transform_context.new(
					source,
					file_path,
					self.config.root,
					rule,
					scope_map,
					replacements,
					if options ~= nil and options.resolved_requires ~= nil
						then options.resolved_requires[file_path]
						else resolved_requires
				)
				const replacement_count = #replacements
				const ran, rule_error = pcall(function()
					rule.run(parsed.tree.root, context)
				end)
				if not ran then
					while #replacements > replacement_count do
						table.remove(replacements)
					end
					table.insert(
						processing_errors,
						create_error("rule_error", `transform '{rule.name}' failed: {tostring(rule_error)}`, file_path)
					)
					break
				end
			end
			if #processing_errors > 0 then
				break
			end

			if #replacements > 0 then
				const applied = replacement.apply(source, replacements)
				if not applied.ok then
					table.insert(
						processing_errors,
						create_error("replacement_conflict", applied.error.message, file_path)
					)
					break
				end

				source = applied.source
				const reparsed = parse.source(source, file_path)
				if not reparsed.ok then
					table.insert(processing_errors, create_error("parse_error", reparsed.error.message, file_path))
					break
				end
				parsed = reparsed
			end
		end

		const changed = source ~= original_source
		if changed then
			files_changed += 1
		end
		table.insert(output, { file_path = file_path, source = source, changed = changed })
	end

	if #processing_errors == 0 and options ~= nil and options.write == true then
		if self.config.output == nil then
			table.insert(processing_errors, create_error("output_error", "project has no output emitter", nil))
		else
			const files_to_emit = {}
			for _, file in output do
				table.insert(files_to_emit, { file_path = file.file_path, source = file.source })
			end
			const emitted = self.config.output:emit(files_to_emit, self.config.file_system, self.config.root)
			if not emitted.ok then
				table.insert(
					processing_errors,
					create_error(emitted.error.code, emitted.error.message, emitted.error.path)
				)
			else
				files_written = emitted.files_written
			end
		end
	end

	return {
		ok = #processing_errors == 0,
		files_processed = files_processed,
		files_changed = files_changed,
		files_written = files_written,
		files = output,
		diagnostics = diagnostics,
		errors = processing_errors,
		duration_milliseconds = elapsed(),
	}
end

transform.run = run

return transform
