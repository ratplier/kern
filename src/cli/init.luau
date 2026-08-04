--!strict

const arguments = require("@cli/cmd/parse")
const render = require("@cli/out/render")
const run = require("@cli/cmd/run")

const cli_types = require("@cli/types")
const project_types = require("@kern/project/types")

export type Command = cli_types.Command
export type Arguments = cli_types.Arguments
export type ParseResult = cli_types.ParseResult
export type RunResult = cli_types.RunResult

local cli = {}

function cli.parse(values: { string }): cli_types.ParseResult
	return arguments.parse(values)
end

function cli.run(project: project_types.Project, values: cli_types.Arguments): cli_types.RunResult
	return run.project(project, values)
end

function cli.render(value: cli_types.RunResult): string
	return render.value(value)
end

function cli.exit_code(value: cli_types.RunResult): number
	return value.exit_code
end

function cli.usage(): string
	return arguments.usage()
end

return cli
