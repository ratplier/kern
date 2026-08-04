--!strict

const path = require("@kern/core/path")
const require_types = require("@kern/require")
const result = require("@kern/core/result")
const file_system_types = require("@kern/fs/types")

export type ModuleEdge = {
	request: string,
	source_path: string,
	destination_path: string,
	span: { start: number, finish: number },
}

export type ModuleNode = {
	source_path: string,
	output_path: string?,
	dependencies: { ModuleEdge },
	dependents: { ModuleEdge },
}

export type ModuleGraph = {
	entries: { string },
	nodes: { [string]: ModuleNode },
	ordered_paths: { string },
}

export type GraphErrorCode =
	"filesystem_error"
	| "parse_error"
	| "missing_module"
	| "ambiguous_module"
	| "unknown_alias"
	| "path_escape"
	| "unsupported_require"
	| "module_cycle"
	| "invalid_entry"

export type GraphError = {
	code: GraphErrorCode,
	message: string,
	source_path: string?,
	request: string?,
	cycle: { string }?,
}

local graph = {}

const function error_value(code: GraphErrorCode, message: string, source_path: string?, request: string?): GraphError
	return { code = code, message = message, source_path = source_path, request = request, cycle = nil }
end

const function build(
	entries: { string },
	file_system: file_system_types.Filesystem,
	project_root: string,
	resolver: require_types.RequireResolver,
	sources: { [string]: string }?
): result.Result<ModuleGraph, GraphError>
	const nodes: { [string]: ModuleNode } = {}
	const state: { [string]: "visiting" | "visited" } = {}
	const stack = {}
	const ordered = {}

	local visit: (string) -> result.Result<nil, GraphError>
	visit = function(source_path: string): result.Result<nil, GraphError>
		if state[source_path] == "visited" then
			return { ok = true, value = nil }
		end
		if state[source_path] == "visiting" then
			const cycle = {}
			for index, value in stack do
				if value == source_path then
					for cycle_index = index, #stack do
						table.insert(cycle, stack[cycle_index])
					end
					break
				end
			end
			table.insert(cycle, source_path)
			return {
				ok = false,
				error = {
					code = "module_cycle",
					message = `module cycle detected: {table.concat(cycle, " → ")}`,
					source_path = source_path,
					cycle = cycle,
				},
			}
		end

		local source: string
		if sources ~= nil and sources[source_path] ~= nil then
			source = sources[source_path]
		else
			const source_result = file_system:read_file(source_path)
			if not source_result.ok then
				return {
					ok = false,
					error = error_value("filesystem_error", source_result.error.message, source_path, nil),
				}
			end
			source = source_result.value
		end

		state[source_path] = "visiting"
		table.insert(stack, source_path)
		local node = nodes[source_path]
		if node == nil then
			const created: ModuleNode = {
				source_path = source_path,
				output_path = nil,
				dependencies = {},
				dependents = {},
			}
			nodes[source_path] = created
			node = created
		end

		const scanned = require_types.scan(source)
		if not scanned.ok then
			-- TODO(luau): widened resolver error-code union.
			const error_code = scanned.error.code :: GraphErrorCode
			return { ok = false, error = error_value(error_code, scanned.error.message, source_path, nil) }
		end
		for _, request in scanned.value do
			const resolved = resolver:resolve(source_path, request.request, file_system, project_root)
			if not resolved.ok then
				-- TODO(luau): widened resolver error-code union.
				const error_code = resolved.error.code :: GraphErrorCode
				return {
					ok = false,
					error = error_value(error_code, resolved.error.message, source_path, request.request),
				}
			end

			const edge = {
				request = request.request,
				source_path = source_path,
				destination_path = resolved.value,
				span = request.span,
			}
			table.insert(node.dependencies, edge)
			const dependency = nodes[resolved.value]
			if dependency == nil then
				const dependency_node: ModuleNode = {
					source_path = resolved.value,
					output_path = nil,
					dependencies = {},
					dependents = {},
				}
				nodes[resolved.value] = dependency_node
			end
			table.insert(nodes[resolved.value].dependents, edge)

			const visited = visit(resolved.value)
			if not visited.ok then
				return visited
			end
		end

		table.remove(stack)
		state[source_path] = "visited"
		table.insert(ordered, source_path)
		return { ok = true, value = nil }
	end

	const normalized_entries = {}
	const seen_entries = {}
	for _, entry in entries do
		const normalized = path.normalize(entry)
		if not path.is_inside(project_root, normalized) then
			return {
				ok = false,
				error = error_value("path_escape", `entry '{entry}' escapes the project root`, entry, nil),
			}
		end
		if seen_entries[normalized] or not file_system:is_file(normalized) then
			return { ok = false, error = error_value("invalid_entry", `entry '{entry}' is not a file`, entry, nil) }
		end
		seen_entries[normalized] = true
		table.insert(normalized_entries, normalized)
	end

	for _, entry in normalized_entries do
		const visited = visit(entry)
		if not visited.ok then
			return visited
		end
	end

	return { ok = true, value = { entries = normalized_entries, nodes = nodes, ordered_paths = ordered } }
end

graph.build = build

return graph
