--!strict

const project_types = require("@kern/project/types")

export type Command = "lint" | "transform" | "build" | "check"

export type Arguments = {
	command: Command,
	fix: boolean,
	check: boolean,
	paths: { string },
}

export type ParseResult =
	{
		ok: true,
		value: Arguments,
	}
	| {
		ok: false,
		error: string,
	}

export type RunResult = {
	ok: boolean,
	exit_code: number,
	command: Command,
	value: project_types.LintResult | project_types.TransformResult | project_types.BuildResult,
}

return nil
