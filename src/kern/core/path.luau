--!strict

const path = {}

const function split(value: string): { string }
	const parts: { string } = {}

	for part in value:gmatch("[^/]+") do
		table.insert(parts, part)
	end

	return parts
end

function path.normalize(value: string): string
	if typeof(value) ~= "string" then
		error("kern: path must be a string", 2)
	end
	const replaced = value:gsub("\\", "/")
	const absolute = replaced:sub(1, 1) == "/"
	local parts: { string } = {}

	for _, part in split(replaced) do
		const current_part: string = part
		if current_part == ".." then
			if #parts > 0 and parts[#parts] ~= ".." then
				table.remove(parts)
			elseif not absolute then
				table.insert(parts, current_part)
			end
		elseif current_part ~= "." and current_part ~= "" then
			table.insert(parts, current_part)
		end
	end

	const joined = table.concat(parts, "/")

	if absolute then
		return `/{joined}`
	end

	return joined
end

function path.join(...: string): string
	const values = { ... }
	const combined = table.concat(values, "/")

	return path.normalize(combined)
end

function path.directory_name(value: string): string
	const normalized = path.normalize(value)
	const slash = normalized:match("^.*()/")

	if slash == nil then
		return ""
	end

	return normalized:sub(1, slash - 1)
end

function path.base_name(value: string): string
	const normalized = path.normalize(value)
	const slash = normalized:match("^.*()/")

	if slash == nil then
		return normalized
	end

	return normalized:sub(slash + 1)
end

function path.extension(value: string): string
	const base = path.base_name(value)
	return base:match("(%.[^.]*)$") or ""
end

function path.remove_extension(value: string, extensions: { string }): string
	for _, extension in extensions do
		if value:sub(-#extension) == extension then
			return value:sub(1, -#extension - 1)
		end
	end

	return value
end

function path.relative(from_directory: string, destination: string): string
	const from = split(path.normalize(from_directory))
	const to = split(path.normalize(destination))

	local common = 0
	while common < #from and common < #to and from[common + 1] == to[common + 1] do
		common += 1
	end

	const parts = {}

	for _ = common + 1, #from do
		table.insert(parts, "..")
	end

	for index = common + 1, #to do
		table.insert(parts, to[index])
	end

	return table.concat(parts, "/")
end

function path.is_inside(root: string, value: string): boolean
	const normalized_root = path.normalize(root)
	const normalized_value = path.normalize(value)

	if normalized_root == "" then
		return not path.is_absolute(value) and normalized_value ~= ".." and normalized_value:sub(1, 3) ~= "../"
	end

	return normalized_value == normalized_root or normalized_value:sub(1, #normalized_root + 1) == `{normalized_root}/`
end

function path.is_relative_request(value: string): boolean
	return value:sub(1, 2) == "./" or value:sub(1, 3) == "../"
end

function path.is_absolute(value: string): boolean
	return value:sub(1, 1) == "/" or value:match("^%a:[/\\]") ~= nil
end

return path
