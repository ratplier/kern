--!strict

const errors = require("@kern/core/errors")
const graph = require("@kern/core/graph")
const replacement = require("@kern/syntax/replacement")
const require_resolver = require("@kern/require")
const result = require("@kern/core/result")
const file_system_types = require("@kern/fs/types")

const project_types = require("@kern/project/types")

local build = {}

const function blocks_build(severity: string, minimum_failure_severity: string): boolean
	const levels = { hint = 1, info = 2, warn = 3, error = 4 }
	return (levels[severity] or 4) >= (levels[minimum_failure_severity] or 4)
end

const function create_error(
	code: errors.ProcessingErrorCode,
	message: string,
	file_path: string?
): errors.ProcessingError
	return { code = code, message = message, file_path = file_path, notes = {} }
end

const function resolve_requests(
	source_path: string,
	source: string,
	resolver: require_resolver.RequireResolver,
	file_system: file_system_types.Filesystem,
	project_root: string
): result.Result<{ require_resolver.ResolvedRequire }, require_resolver.RequireError>
	const scanned = require_resolver.scan(source)
	if not scanned.ok then
		return { ok = false, error = scanned.error }
	end

	const resolved_requests = {}
	for _, request in scanned.value do
		const resolved = resolver:resolve(source_path, request.request, file_system, project_root)
		if not resolved.ok then
			return resolved
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

const function run(self: project_types.Project, options: { write: boolean }?): project_types.BuildResult
	const start_time = os.clock()
	const function elapsed(): number
		return (os.clock() - start_time) * 1000
	end
	const diagnostics = {}
	const processing_errors: { errors.ProcessingError } = {}
	const outputs = {}

	if self.config.output == nil then
		table.insert(processing_errors, create_error("output_error", "project has no output emitter", nil))
		return {
			ok = false,
			files_processed = 0,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	const lint_result = self:lint()
	for _, diagnostic in lint_result.diagnostics do
		table.insert(diagnostics, diagnostic)
	end
	local has_blocking_diagnostic = false
	for _, diagnostic in diagnostics do
		if blocks_build(diagnostic.severity, self.config.diagnostics.minimum_failure_severity) then
			has_blocking_diagnostic = true
			break
		end
	end
	if not lint_result.ok or has_blocking_diagnostic then
		for _, error_value in lint_result.errors do
			table.insert(processing_errors, error_value)
		end
		return {
			ok = false,
			files_processed = lint_result.files_processed,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	const resolver = self.config.require_resolver or require_resolver.new({ aliases = {} })
	const initial_graph = graph.build(self.config.entries, self.config.file_system, self.config.root, resolver)
	if not initial_graph.ok then
		table.insert(
			processing_errors,
			create_error(initial_graph.error.code, initial_graph.error.message, initial_graph.error.source_path)
		)
		return {
			ok = false,
			files_processed = 0,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	const original_sources: { [string]: string } = {}
	local source_map: { [string]: string } = {}
	for _, source_path in initial_graph.value.ordered_paths do
		const source_result = self.config.file_system:read_file(source_path)
		if not source_result.ok then
			table.insert(processing_errors, create_error("filesystem_error", source_result.error.message, source_path))
		else
			original_sources[source_path] = source_result.value
			source_map[source_path] = source_result.value
		end
	end
	if #processing_errors > 0 then
		return {
			ok = false,
			files_processed = 0,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	const syntax_result = self:transform({
		phases = { "syntax" },
		paths = initial_graph.value.ordered_paths,
		sources = source_map,
	})
	if not syntax_result.ok then
		for _, error_value in syntax_result.errors do
			table.insert(processing_errors, error_value)
		end
		return {
			ok = false,
			files_processed = #initial_graph.value.ordered_paths,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end
	for _, file in syntax_result.files do
		source_map[file.file_path] = file.source
	end

	const syntax_graph =
		graph.build(self.config.entries, self.config.file_system, self.config.root, resolver, source_map)
	if not syntax_graph.ok then
		table.insert(
			processing_errors,
			create_error(syntax_graph.error.code, syntax_graph.error.message, syntax_graph.error.source_path)
		)
		return {
			ok = false,
			files_processed = 0,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	for _, source_path in syntax_graph.value.ordered_paths do
		if source_map[source_path] == nil then
			const source_result = self.config.file_system:read_file(source_path)
			if not source_result.ok then
				table.insert(
					processing_errors,
					create_error("filesystem_error", source_result.error.message, source_path)
				)
			else
				source_map[source_path] = source_result.value
				original_sources[source_path] = source_result.value
			end
		end
	end
	if #processing_errors > 0 then
		return {
			ok = false,
			files_processed = #syntax_graph.value.ordered_paths,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	const resolved_requires: { [string]: { require_resolver.ResolvedRequire } } = {}
	for _, source_path in syntax_graph.value.ordered_paths do
		const resolved =
			resolve_requests(source_path, source_map[source_path], resolver, self.config.file_system, self.config.root)
		if not resolved.ok then
			table.insert(processing_errors, create_error(resolved.error.code, resolved.error.message, source_path))
		else
			for _, request in resolved.value do
				request.output_path = self.config.output:output_path(request.resolved_path, self.config.root)
			end
			resolved_requires[source_path] = resolved.value
		end
	end
	if #processing_errors > 0 then
		return {
			ok = false,
			files_processed = #syntax_graph.value.ordered_paths,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	for _, source_path in syntax_graph.value.ordered_paths do
		const replacements: { replacement.Replacement } = {}
		for _, request in resolved_requires[source_path] do
			const require_replacement: replacement.Replacement = {
				owner_kind = "require",
				owner_name = resolver.name,
				span = request.argument_span,
				source = resolver:rewrite(source_path, request.resolved_path, request.request),
			}
			table.insert(replacements, require_replacement)
		end
		const applied = replacement.apply(source_map[source_path], replacements)
		if not applied.ok then
			table.insert(processing_errors, create_error("replacement_conflict", applied.error.message, source_path))
		else
			source_map[source_path] = applied.source
		end
	end
	if #processing_errors > 0 then
		return {
			ok = false,
			files_processed = #syntax_graph.value.ordered_paths,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	const module_result = self:transform({
		phases = { "module" },
		paths = syntax_graph.value.ordered_paths,
		sources = source_map,
		resolved_requires = resolved_requires,
	})
	if not module_result.ok then
		for _, error_value in module_result.errors do
			table.insert(processing_errors, error_value)
		end
		return {
			ok = false,
			files_processed = #syntax_graph.value.ordered_paths,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end
	for _, file in module_result.files do
		source_map[file.file_path] = file.source
	end

	const module_graph =
		graph.build(self.config.entries, self.config.file_system, self.config.root, resolver, source_map)
	if not module_graph.ok then
		table.insert(
			processing_errors,
			create_error(module_graph.error.code, module_graph.error.message, module_graph.error.source_path)
		)
		return {
			ok = false,
			files_processed = 0,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	for _, source_path in module_graph.value.ordered_paths do
		if source_map[source_path] == nil then
			const source_result = self.config.file_system:read_file(source_path)
			if not source_result.ok then
				table.insert(
					processing_errors,
					create_error("filesystem_error", source_result.error.message, source_path)
				)
			else
				source_map[source_path] = source_result.value
				original_sources[source_path] = source_result.value
			end
		end
	end
	if #processing_errors > 0 then
		return {
			ok = false,
			files_processed = #module_graph.value.ordered_paths,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	const finalize_result = self:transform({
		phases = { "finalize" },
		paths = module_graph.value.ordered_paths,
		sources = source_map,
	})
	if not finalize_result.ok then
		for _, error_value in finalize_result.errors do
			table.insert(processing_errors, error_value)
		end
		return {
			ok = false,
			files_processed = #module_graph.value.ordered_paths,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end
	for _, file in finalize_result.files do
		source_map[file.file_path] = file.source
	end

	const final_graph =
		graph.build(self.config.entries, self.config.file_system, self.config.root, resolver, source_map)
	if not final_graph.ok then
		table.insert(
			processing_errors,
			create_error(final_graph.error.code, final_graph.error.message, final_graph.error.source_path)
		)
		return {
			ok = false,
			files_processed = 0,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	for _, source_path in final_graph.value.ordered_paths do
		if source_map[source_path] == nil then
			const source_result = self.config.file_system:read_file(source_path)
			if not source_result.ok then
				table.insert(
					processing_errors,
					create_error("filesystem_error", source_result.error.message, source_path)
				)
			else
				source_map[source_path] = source_result.value
				original_sources[source_path] = source_result.value
			end
		end
	end
	if #processing_errors > 0 then
		return {
			ok = false,
			files_processed = #final_graph.value.ordered_paths,
			files_changed = 0,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	const files = {}
	local files_changed = 0
	for _, source_path in final_graph.value.ordered_paths do
		const source = source_map[source_path]
		if original_sources[source_path] ~= source then
			files_changed += 1
		end
		table.insert(files, { file_path = source_path, source = source })
		const output_path = self.config.output:output_path(source_path, self.config.root)
		final_graph.value.nodes[source_path].output_path = output_path
		table.insert(outputs, {
			source_path = source_path,
			output_path = output_path,
		})
	end

	if options ~= nil and options.write == false then
		return {
			ok = true,
			files_processed = #files,
			files_changed = files_changed,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			graph = final_graph.value,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	const emitted = self.config.output:emit(files, self.config.file_system, self.config.root)
	if not emitted.ok then
		table.insert(processing_errors, create_error(emitted.error.code, emitted.error.message, emitted.error.path))
		return {
			ok = false,
			files_processed = #files,
			files_changed = files_changed,
			files_written = 0,
			diagnostics = diagnostics,
			errors = processing_errors,
			graph = final_graph.value,
			outputs = outputs,
			duration_milliseconds = elapsed(),
		}
	end

	return {
		ok = true,
		files_processed = #files,
		files_changed = files_changed,
		files_written = emitted.files_written,
		diagnostics = diagnostics,
		errors = processing_errors,
		graph = final_graph.value,
		outputs = outputs,
		duration_milliseconds = elapsed(),
	}
end

build.run = run

return build
