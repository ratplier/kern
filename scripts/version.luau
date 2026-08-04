--!strict

const file_system = require("@std/fs")
const process = require("@std/process")

const function normalize(value)
	return value:gsub("^%s+", ""):gsub("%s+$", "")
end

const function valid(value)
	return value:match("^%d+%.%d+%.%d+[%w%.%-]*$") ~= nil
end

const function update(value)
	if not valid(value) then
		error(`kern: '{value}' is not a valid semantic version`)
	end

	file_system.writeStringToFile("VERSION", `{value}\n`)
	print(`kern: version set to {value}`)
end

const function run(script)
	const result = process.run({ "lute", "run", script }, { stdio = "inherit" })
	if result.exitcode ~= 0 then
		process.exit(result.exitcode)
	end
end

const command = process.args[2]
if command == nil then
	const version = normalize(file_system.readFileToString("VERSION"))
	print(version)
	process.exit(0)
end

const version = process.args[3]
if version == nil or version == "" then
	error(`kern: expected a version after '{command}'`)
end

if command == "set" then
	update(version)
	process.exit(0)
end

if command == "prepare" then
	update(version)
	run("scripts/generate_modules.luau")
	run("scripts/generate_types.luau")
	run("scripts/generate_docs.luau")
	print(`kern: release {version} is prepared; review and commit VERSION and generated files before tagging`)
	process.exit(0)
end

error(`kern: unknown version command '{command}'; use 'set' or 'prepare'`)
