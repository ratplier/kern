--!strict

const errors = require("@kern/core/errors")
const lint_context = require("@kern/lint/context")
const diagnostic = require("@kern/lint/diagnostic")
const parse = require("@kern/syntax/parse")
const replacement = require("@kern/syntax/replacement")
const scope = require("@kern/scope")
const path = require("@kern/core/path")

const project_types = require("@kern/project/types")

local lint = {}

const function create_error(
	code: errors.ProcessingErrorCode,
	message: string,
	file_path: string?,
	span: { start: number, finish: number }?,
	line: number?,
	column: number?
): errors.ProcessingError
	return {
		code = code,
		message = message,
		file_path = file_path,
		span = span,
		line = line,
		column = column,
		notes = {},
	}
end

const function run(self: project_types.Project, options: project_types.LintOptions?): project_types.LintResult
	const start_time = os.clock()
	const function elapsed(): number
		return (os.clock() - start_time) * 1000
	end
	const diagnostics = {}
	const processing_errors: { errors.ProcessingError } = {}
	local files_processed = 0
	local files_changed = 0
	local file_paths: { string }
	if options ~= nil and options.paths ~= nil then
		file_paths = table.clone(options.paths)
		table.sort(file_paths)
		for _, file_path in file_paths do
			const candidate = path.normalize(file_path)
			const normalized = if path.is_inside(self.config.root, candidate)
				then candidate
				else path.join(self.config.root, candidate)
			if not path.is_inside(self.config.root, normalized) or not self.config.file_system:is_file(normalized) then
				table.insert(
					processing_errors,
					create_error("invalid_entry", `lint path '{file_path}' is not a file`, file_path, nil, nil, nil)
				)
			end
		end
		if #processing_errors > 0 then
			return {
				ok = false,
				files_processed = 0,
				files_changed = 0,
				diagnostics = diagnostics,
				errors = processing_errors,
				duration_milliseconds = elapsed(),
			}
		end
	else
		const found = self.config.file_system:find(self.config.include, self.config.exclude)

		if not found.ok then
			table.insert(
				processing_errors,
				create_error("filesystem_error", found.error.message, found.error.path, nil, nil, nil)
			)
			return {
				ok = false,
				files_processed = 0,
				files_changed = 0,
				diagnostics = diagnostics,
				errors = processing_errors,
				duration_milliseconds = elapsed(),
			}
		end
		file_paths = found.value
	end

	for _, file_path in file_paths do
		const source_result = self.config.file_system:read_file(file_path)
		if not source_result.ok then
			table.insert(
				processing_errors,
				create_error("filesystem_error", source_result.error.message, file_path, nil, nil, nil)
			)
			continue
		end

		files_processed += 1
		const parsed = parse.source(source_result.value, file_path)
		if not parsed.ok then
			table.insert(
				processing_errors,
				create_error(
					"parse_error",
					parsed.error.message,
					parsed.error.file_path,
					parsed.error.span,
					parsed.error.line,
					parsed.error.column
				)
			)
			continue
		end

		for _, rule in self.config.lint_rules do
			local scope_map = nil
			if rule.scope ~= nil then
				const parsed_scope = scope.parse(source_result.value, rule.scope)
				if not parsed_scope.ok then
					table.insert(
						processing_errors,
						create_error(
							"scope_error",
							parsed_scope.error.message,
							file_path,
							parsed_scope.error.span,
							nil,
							nil
						)
					)
					continue
				end
				scope_map = parsed_scope.value
			end

			const context = lint_context.new(
				source_result.value,
				file_path,
				self.config.root,
				rule,
				self.config.lint_components[rule.name] or "project",
				scope_map
			)
			const ran, rule_error = pcall(function()
				rule.run(parsed.tree.root, context)
			end)
			if not ran then
				table.insert(
					processing_errors,
					create_error("rule_error", `lint rule '{rule.name}' failed: {tostring(rule_error)}`, file_path, nil, nil, nil)
				)
				continue
			end
			for _, value in context.diagnostics do
				table.insert(diagnostics, value)
			end
		end
	end

	table.sort(diagnostics, diagnostic.compare)
	if options ~= nil and options.fix then
		const fixes: { [string]: { replacement.Replacement } } = {}
		for _, value in diagnostics do
			if value.fix ~= nil then
				const file_fixes = fixes[value.file_path] or {}
				const fix: replacement.Replacement = {
					owner_kind = "lint_fix",
					owner_name = value.rule,
					span = value.fix.span,
					source = value.fix.replacement,
				}
				table.insert(file_fixes, fix)
				fixes[value.file_path] = file_fixes
			end
		end

		const fix_paths = {}
		for file_path in fixes do
			table.insert(fix_paths, file_path)
		end
		table.sort(fix_paths)

		for _, file_path in fix_paths do
			const file_fixes = fixes[file_path]
			const source_result = self.config.file_system:read_file(file_path)
			if not source_result.ok then
				table.insert(
					processing_errors,
					create_error("filesystem_error", source_result.error.message, file_path, nil, nil, nil)
				)
				continue
			end
			const applied = replacement.apply(source_result.value, file_fixes)
			if not applied.ok then
				table.insert(
					processing_errors,
					create_error("replacement_conflict", applied.error.message, file_path, nil, nil, nil)
				)
				continue
			end
			if applied.source ~= source_result.value then
				const written = self.config.file_system:write_file(file_path, applied.source)
				if not written.ok then
					table.insert(
						processing_errors,
						create_error("filesystem_error", written.error.message, file_path, nil, nil, nil)
					)
				else
					files_changed += 1
				end
			end
		end
	end
	return {
		ok = #processing_errors == 0,
		files_processed = files_processed,
		files_changed = files_changed,
		diagnostics = diagnostics,
		errors = processing_errors,
		duration_milliseconds = elapsed(),
	}
end

lint.run = run

return lint
