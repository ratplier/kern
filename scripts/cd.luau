--!strict

const path = require("@std/path")
const process = require("@std/process")

const function default_output_path(): string
	return path.format(path.join("bin", "build"))
end

const function check_entrypoint(): number
	const result = process.run({ "lute", "check", "src/cli/run.luau" }, {
		stdio = "inherit",
	})

	return result.exitcode
end

const function compile(output: string): number
	const result = process.run({ "lute", "run", "scripts/compile.luau", output }, {
		stdio = "inherit",
	})

	return result.exitcode
end

const output = process.args[2] or default_output_path()
const checked = check_entrypoint()
if checked ~= 0 then
	process.exit(checked)
end

process.exit(compile(output))
