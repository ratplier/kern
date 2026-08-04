--!nocheck

const file_system = require("@std/fs")
const json = require("@std/json")
const path = require("@std/path")

const sections = {
	{ id = "authoring", name = "Authoring", description = "Create components, rules, transforms, and scoped tooling.", within = { kern = true, Component = true, Lint = true, Transform = true, Scope = true } },
	{ id = "projects-and-output", name = "Projects and output", description = "Configure projects, module resolution, filesystems, and build output.", within = { Project = true, Output = true, Require = true, Filesystem = true } },
	{ id = "syntax-and-queries", name = "Syntax and queries", description = "Parse Luau, create source nodes, and inspect syntax with queries.", within = { Syntax = true, Query = true, Queries = true, Calls = true } },
	{ id = "core-and-cli", name = "Core and CLI", description = "CLI helpers and the result, graph, and error primitives behind kern.", within = { CLI = true, Errors = true, Graph = true, Result = true } },
}

const function trim(value)
	return value:match("^%s*(.-)%s*$") or ""
end

const function collect(directory, files)
	for _, entry in file_system.listDirectory(directory) do
		const file_path = path.format(path.join(directory, entry.name)):gsub("\\", "/")
		if entry.type == "dir" then
			collect(file_path, files)
		elseif entry.type == "file" and path.extname(file_path) == ".luau" then
			table.insert(files, file_path)
		end
	end
end

const function declaration_after(source, offset)
	local type_lines = nil
	local type_depth = 0
	for line in source:sub(offset):gmatch("[^\n]+") do
		const value = trim(line)
		if type_lines ~= nil then
			table.insert(type_lines, line)
			type_depth += select(2, value:gsub("{", ""))
			type_depth -= select(2, value:gsub("}", ""))
			if type_depth <= 0 then
				return table.concat(type_lines, "\n")
			end
			continue
		end
		if value == "" or value:sub(1, 2) == "--" then
			continue
		end
		if value:sub(1, 12) == "export type " then
			type_lines = { line }
			type_depth = select(2, value:gsub("{", "")) - select(2, value:gsub("}", ""))
			if type_depth <= 0 then
				return line
			end
		elseif value:sub(1, 9) == "function " or value:match("^[%a_][%w_%.]*%s*=") then
			return value
		end
		return nil
	end
	return nil
end

const function parse_comment(content)
	local body = {}
	local parameters = {}
	local returns = nil
	local within = "Other"
	for line in (content .. "\n"):gmatch("(.-)\n") do
		const value = trim(line)
		if value:sub(1, 8) == "@within " then
			within = trim(value:sub(9))
		elseif value:sub(1, 7) == "@param " then
			const name, description = value:sub(8):match("^(%S+)%s+(.+)$")
			table.insert(parameters, { name = name or value:sub(8), description = description or "" })
		elseif value:sub(1, 8) == "@return " then
			returns = value:sub(9)
		else
			table.insert(body, value)
		end
	end
	while #body > 0 and body[1] == "" do table.remove(body, 1) end
	while #body > 0 and body[#body] == "" do table.remove(body) end
	return within, body, parameters, returns
end

const function details(declaration)
	local name = declaration:match("^function%s+([%w_%.:]+)")
	if name then return name, declaration, "function" end
	name = declaration:match("^export%s+type%s+([%w_]+)")
	if name then return name, declaration, "type" end
	name = declaration:match("^([%w_%.]+)%s*=")
	return name or declaration, declaration, "value"
end

const function add_entry(content, source, finish, source_path, entries)
	const declaration = declaration_after(source, finish + 1)
	if declaration == nil then return end
	const within, body, parameters, returns = parse_comment(content)
	if #body == 0 and #parameters == 0 and returns == nil then return end
	const name, signature, kind = details(declaration)
	table.insert(entries, { within = within, name = name, kind = kind, signature = signature, description = body, parameters = parameters, returns = returns, source_path = source_path })
end

const function parse_blocks(source, source_path, entries)
	local cursor = 1
	while true do
		const _, finish, content = source:find("%-%-%[=%[(.-)%]=%]", cursor)
		if finish == nil or content == nil then break end
		add_entry(content, source, finish, source_path, entries)
		cursor = finish + 1
	end
end

const function section_for(within)
	for _, section in sections do
		if section.within[within] then return section end
	end
	return sections[#sections]
end

const function generate()
	local files = {}
	collect("types/kern", files)
	table.sort(files)
	local grouped = {}
	for _, section in sections do grouped[section.id] = {} end
	for _, source_path in files do
		local entries = {}
		const source = file_system.readFileToString(source_path)
		parse_blocks(source, source_path, entries)
		for _, entry in entries do table.insert(grouped[section_for(entry.within).id], entry) end
	end
	local output_sections = {}
	for _, section in sections do
		const entries = grouped[section.id]
		table.sort(entries, function(left, right) return left.name < right.name end)
		table.insert(output_sections, { id = section.id, name = section.name, description = section.description, entries = entries })
	end
	if not file_system.exists("docs/api") then file_system.createDirectory("docs/api", { makeParents = true }) end
	const source = json.serialize({ schema_version = 1, sections = output_sections }, true):gsub("[ \t]+\n", "\n")
	file_system.writeStringToFile("docs/api/api.json", source)
	print("kern: generated docs/api/api.json")
end

generate()
