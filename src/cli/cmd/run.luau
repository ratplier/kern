--!strict

const cli_types = require("@cli/types")
const exit_code = require("@cli/out/exit")

const lint_types = require("@kern/lint/types")
const project_types = require("@kern/project/types")

local run = {}

const function has_error_diagnostic(diagnostics: { lint_types.Diagnostic }): boolean
	for _, diagnostic in diagnostics do
		if diagnostic.severity == "error" then
			return true
		end
	end

	return false
end

const function lint(project: project_types.Project, arguments: cli_types.Arguments): cli_types.RunResult
	const value = project:lint({
		fix = arguments.fix,
		paths = if #arguments.paths > 0 then arguments.paths else nil,
	})
	if not value.ok then
		return { ok = false, exit_code = exit_code.from_errors(value.errors), command = "lint", value = value }
	end

	if arguments.fix then
		const rerun = project:lint({
			paths = if #arguments.paths > 0 then arguments.paths else nil,
		})
		if not rerun.ok then
			return { ok = false, exit_code = exit_code.from_errors(rerun.errors), command = "lint", value = rerun }
		end
		const has_blocking = has_error_diagnostic(rerun.diagnostics)
		return {
			ok = not has_blocking,
			exit_code = if has_blocking then 1 else 0,
			command = "lint",
			value = rerun,
		}
	end

	const has_blocking = has_error_diagnostic(value.diagnostics)
	return {
		ok = not has_blocking,
		exit_code = if has_blocking then 1 else 0,
		command = "lint",
		value = value,
	}
end

const function transform(project: project_types.Project, arguments: cli_types.Arguments): cli_types.RunResult
	const value = project:transform({
		paths = if #arguments.paths > 0 then arguments.paths else nil,
		write = not arguments.check,
	})
	if not value.ok then
		return { ok = false, exit_code = exit_code.from_errors(value.errors), command = "transform", value = value }
	end

	const is_check_failure = arguments.check and value.files_changed > 0
	return {
		ok = not is_check_failure,
		exit_code = if is_check_failure then 1 else 0,
		command = "transform",
		value = value,
	}
end

const function check(project: project_types.Project, _arguments: cli_types.Arguments): cli_types.RunResult
	const value = project:check()
	return {
		ok = value.ok,
		exit_code = if value.ok then 0 else exit_code.from_errors(value.errors),
		command = "check",
		value = value,
	}
end

const function build(project: project_types.Project, _arguments: cli_types.Arguments): cli_types.RunResult
	const value = project:build()
	return {
		ok = value.ok,
		exit_code = if value.ok then 0 else exit_code.from_errors(value.errors),
		command = "build",
		value = value,
	}
end

type CommandHandler = (project: project_types.Project, arguments: cli_types.Arguments) -> cli_types.RunResult

local commands: { [cli_types.Command]: CommandHandler } = {
	lint = lint,
	transform = transform,
	check = check,
	build = build,
}

function run.project(project: project_types.Project, arguments: cli_types.Arguments): cli_types.RunResult
	const handler = commands[arguments.command]
	if handler ~= nil then
		return handler(project, arguments)
	end

	error(`kern: unsupported command '{arguments.command}'`, 0)
end

return run
