--!nocheck

const Project = require("@kern/project")

--[=[
	@within CLI

	Arguments accepted by Kern's project command runner.
]=]
export type Arguments = {
	command: "lint" | "transform" | "build" | "check",
	fix: boolean,
	check: boolean,
	paths: { string },
}

--[=[
	@within CLI

	The result of parsing command-line arguments.
]=]
export type ParseResult = { ok: true, value: Arguments } | { ok: false, error: string }

--[=[
	@within CLI

	The result returned after running a project command.
]=]
export type RunResult = {
	ok: boolean,
	exit_code: number,
	value: Project.LintResult | Project.TransformResult | Project.BuildResult,
}

local cli = {}

--[=[
	@within CLI

	Parses Kern command arguments without running a project.

	@param values Command-line argument values
	@return The parsed arguments or a validation error
]=]
function cli.parse(values: { string }): ParseResult
	return nil :: any
end

--[=[
	@within CLI

	Runs a parsed command against a Kern project.

	@param project The project to operate on
	@param values Parsed command arguments
	@return The command result and process exit code
]=]
function cli.run(project: Project.Project, values: Arguments): RunResult
	return nil :: any
end

--[=[
	@within CLI

	Formats a command result for terminal output.

	@param value The command result to render
	@return Human-readable terminal output
]=]
function cli.render(value: RunResult): string
	return ""
end

--[=[
	@within CLI

	Returns the process exit code for a command result.

	@param value The command result
	@return Its process exit code
]=]
function cli.exit_code(value: RunResult): number
	return value.exit_code
end

--[=[
	@within CLI

	Returns command-line usage text.

	@return Command-line usage text
]=]
function cli.usage(): string
	return ""
end

return cli
