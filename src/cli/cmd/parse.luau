--!strict

const cli_types = require("@cli/types")

local arguments = {}

const function usage(): string
	return table.concat({
		"usage: kern <command> [path ...] [options]",
		"",
		"commands:",
		"  init                  create default.kern.luau and configure types",
		"  lint [path ...]       report diagnostics",
		"  transform [path ...] write transformed output",
		"  build                 build the configured project",
		"  check                 validate without writing output",
		"  setup                 install matching Kern typedefs",
		"",
		"options:",
		"  --fix                 apply lint fixes",
		"  --check               verify transforms without writing",
		"  --version             show the executable version",
		"  -p, --project <path>  use a specific project file",
		"  -h, --help            show this help",
		"",
		"examples:",
		"  kern init",
		"  kern lint --fix",
		"  kern transform --check src",
		"  kern build",
	}, "\n")
end

const function parse(values: { string }): cli_types.ParseResult
	const command = values[1]
	if command ~= "lint" and command ~= "transform" and command ~= "build" and command ~= "check" then
		return { ok = false, error = `expected a command\n\n{usage()}` }
	end

	local has_fix = false
	local has_check = false
	const paths: { string } = {}
	for index = 2, #values do
		const value = values[index]
		if value == "--fix" then
			if has_fix then
				return { ok = false, error = "duplicate option '--fix'" }
			end
			has_fix = true
		elseif value == "--check" then
			if has_check then
				return { ok = false, error = "duplicate option '--check'" }
			end
			has_check = true
		elseif value == "-h" or value == "--help" then
			return { ok = false, error = usage() }
		elseif value:sub(1, 1) == "-" then
			return { ok = false, error = `unknown option '{value}'` }
		else
			table.insert(paths, value)
		end
	end

	if has_fix and command ~= "lint" then
		return { ok = false, error = "--fix is only valid for lint" }
	end
	if has_check and command ~= "transform" then
		return { ok = false, error = "--check is only valid for transform" }
	end
	if #paths > 0 and command ~= "lint" and command ~= "transform" then
		return { ok = false, error = "paths are only valid for lint and transform" }
	end

	return {
		ok = true,
		value = {
			command = command,
			fix = has_fix,
			check = has_check,
			paths = paths,
		},
	}
end

arguments.parse = parse
arguments.usage = usage

return arguments
