--!strict

const process = require("@std/process")

for _, script in { "scripts/generate_api_json.luau", "scripts/render_api_docs.luau" } do
	const result = process.run({ "lute", "run", script }, { stdio = "inherit" })
	if result.exitcode ~= 0 then
		process.exit(result.exitcode)
	end
end
