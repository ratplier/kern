--!nocheck

const file_system = require("@std/fs")
const json = require("@std/json")

const function append_entry(lines, entry)
	table.insert(lines, `### \`{entry.name}\``)
	table.insert(lines, "")
	table.insert(lines, "```luau")
	table.insert(lines, entry.signature)
	table.insert(lines, "```")
	if #entry.description > 0 then
		table.insert(lines, "")
		for _, line in entry.description do table.insert(lines, line) end
	end
	if #entry.parameters > 0 then
		table.insert(lines, "")
		table.insert(lines, "**Parameters**")
		table.insert(lines, "")
		for _, parameter in entry.parameters do
			if parameter.description == "" then
				table.insert(lines, `- \`{parameter.name}\``)
			else
				table.insert(lines, `- \`{parameter.name}\` — {parameter.description}`)
			end
		end
	end
	if entry.returns ~= nil then
		table.insert(lines, "")
		table.insert(lines, `**Returns:** {entry.returns}`)
	end
	table.insert(lines, "")
end

const function render()
	const api = json.deserialize(file_system.readFileToString("docs/api/api.json"))
	if typeof(api) ~= "table" or typeof(api.sections) ~= "table" then
		error("kern: docs/api/api.json is not valid API documentation data")
	end
	local index = {
		"---",
		"sidebar_position: 1",
		"title: API reference",
		"---",
		"",
		"<!-- Generated from api.json by scripts/render_api_docs.luau. Do not edit directly. -->",
		"",
		"kern's public API, compiled from `--[=[ ... ]=]` documentation comments in [`types/kern`](../../types/kern).",
		"",
		"## Sections",
		"",
	}
	for position, section in api.sections do
		table.insert(index, `- [{section.name}]({section.id}) — {section.description}`)
		local lines = {
			"---",
			`sidebar_position: {position + 1}`,
			`title: {section.name}`,
			"---",
			"",
			"<!-- Generated from api.json by scripts/render_api_docs.luau. Do not edit directly. -->",
			"",
			section.description,
			"",
		}
		local callables = {}
		local types = {}
		for _, entry in section.entries do
			if entry.kind == "type" then
				table.insert(types, entry)
			else
				table.insert(callables, entry)
			end
		end
		if #callables > 0 then
			table.insert(lines, "## API")
			table.insert(lines, "")
			for _, entry in callables do append_entry(lines, entry) end
		end
		if #types > 0 then
			table.insert(lines, "## Types")
			table.insert(lines, "")
			for _, entry in types do append_entry(lines, entry) end
		end
		const source = (table.concat(lines, "\n") .. "\n"):gsub("\n+$", "\n")
		file_system.writeStringToFile(`docs/api/{section.id}.md`, source)
	end
	file_system.writeStringToFile("docs/api/index.md", table.concat(index, "\n") .. "\n")
	print("kern: rendered docs/api")
end

render()
