--!strict

const component = require("@kern/component")
const component_types = require("@kern/component")
const file_system = require("@kern/fs/lute")
const file_system_types = require("@kern/fs/types")

const lint_types = require("@kern/lint/types")
const require_types = require("@kern/require")
const output_types = require("@kern/output")
const path = require("@kern/core/path")

const transform_types = require("@kern/transform")
const project_types = require("@kern/project/types")
const project_lint = require("@kern/project/lint")
const project_transform = require("@kern/project/transform")
const project_build = require("@kern/project/build")

local project = {}

const function copy_strings(values: { string }): { string }
	const copied = {}
	for _, value in values do
		table.insert(copied, value)
	end
	return copied
end

const function validate_patterns(root: string, kind: string, values: { string }): { string }
	const copied = copy_strings(values)
	for index, value in copied do
		if typeof(value) ~= "string" then
			error(`kern: project {kind}[{index}] must be a string`, 2)
		end
		const normalized = path.normalize(value)
		if value == "" or path.is_absolute(value) or normalized == ".." or normalized:sub(1, 3) == "../" then
			error(`kern: invalid {kind} pattern '{value}'`, 2)
		end
	end
	const rooted = {}
	for _, value in copied do
		table.insert(rooted, path.join(root, value))
	end
	return rooted
end

const function validate_severity(value: string): lint_types.Severity
	if value == "hint" then
		return "hint"
	end
	if value == "info" then
		return "info"
	end
	if value == "warn" then
		return "warn"
	end
	if value == "error" then
		return "error"
	end

	error(`kern: invalid minimum failure severity '{value}'`, 2)
end

const function normalize_components(
	values: { component_types.Component | component_types.ComponentMember }
): { component_types.Component }
	const components = {}

	for index, value in values do
		if typeof(value) ~= "table" then
			error("kern: project contains an unknown component member", 2)
		end
		if value.kind == "component" then
			table.insert(components, value)
		else
			table.insert(components, component.new(`anonymous_{index}`, { value }))
		end
	end

	return components
end

const function validate_components(components: { component_types.Component })
	const names = {}

	for _, value in components do
		for _, member in value.members do
			const key = `{member.kind}:{member.name}`
			const previous = names[key]

			if previous ~= nil then
				error(
					`kern: duplicate {member.kind} rule '{member.name}' in components '{previous}' and '{value.name}'`,
					2
				)
			end

			names[key] = value.name
		end
	end
end

const function collect_rules(components: { component_types.Component }): {
	lint_rules: { lint_types.LintRule },
	transform_rules: {
		syntax: { transform_types.TransformRule },
		module: { transform_types.TransformRule },
		finalize: { transform_types.TransformRule },
	},
	lint_components: { [string]: string },
	require_resolver: require_types.RequireResolver?,
	output: output_types.OutputEmitter?,
}
	const lint_rules = {}
	const lint_components: { [string]: string } = {}
	const transform_rules = {
		syntax = {},
		module = {},
		finalize = {},
	}
	local require_resolver: require_types.RequireResolver? = nil
	local output_emitter: output_types.OutputEmitter? = nil

	for _, value in components do
		for _, member in value.members do
			if member.kind == "lint" then
				table.insert(lint_rules, member)
				lint_components[member.name] = value.name
			elseif member.kind == "transform" then
				table.insert(transform_rules[member.phase], member)
			elseif member.kind == "require" then
				if require_resolver ~= nil then
					error("kern: project supports only one require resolver", 2)
				end
				require_resolver = member
			elseif member.kind == "output" then
				if output_emitter ~= nil then
					error("kern: project supports only one output emitter", 2)
				end
				output_emitter = member
			end
		end
	end

	return {
		lint_rules = lint_rules,
		lint_components = lint_components,
		transform_rules = transform_rules,
		require_resolver = require_resolver,
		output = output_emitter,
	}
end

const function validate_entries(root: string, entries: { string }): { string }
	if #entries == 0 then
		error("kern: project requires at least one entry", 2)
	end

	const copied = {}
	const seen = {}

	for index, entry in entries do
		if typeof(entry) ~= "string" then
			error(`kern: project entries[{index}] must be a string`, 2)
		end
		const normalized_entry = path.normalize(entry)
		const normalized = if path.is_inside(root, normalized_entry)
			then normalized_entry
			else path.join(root, normalized_entry)
		if normalized == "" or not path.is_inside(root, normalized) then
			error(`kern: entry '{entry}' is outside project root`, 2)
		end
		if seen[normalized] then
			error(`kern: duplicate project entry '{normalized}'`, 2)
		end

		seen[normalized] = true
		table.insert(copied, normalized)
	end

	return copied
end

const function new(config: project_types.ProjectConfig): project_types.Project
	if typeof(config) ~= "table" then
		error("kern: project configuration must be a table", 2)
	end
	if config.root ~= nil and typeof(config.root) ~= "string" then
		error("kern: project root must be a string", 2)
	end
	if config.root ~= nil then
		const normalized_root = path.normalize(config.root)
		if path.is_absolute(config.root) or normalized_root == ".." or normalized_root:sub(1, 3) == "../" then
			error("kern: project root must be a project-relative directory", 2)
		end
	end
	if typeof(config.entries) ~= "table" then
		error("kern: project entries must be an array of paths", 2)
	end
	if typeof(config.components) ~= "table" then
		error("kern: project components must be an array", 2)
	end
	if config.include ~= nil and typeof(config.include) ~= "table" then
		error("kern: project include must be an array of patterns", 2)
	end
	if config.exclude ~= nil and typeof(config.exclude) ~= "table" then
		error("kern: project exclude must be an array of patterns", 2)
	end
	if config.root == "" then
		error("kern: project root cannot be empty", 2)
	end
	const normalized_root = path.normalize(config.root or ".")
	const root = if normalized_root == "" then "." else normalized_root

	-- TODO(luau): structural Lute filesystem adapter.
	const default_file_system = file_system :: file_system_types.Filesystem

	const components = normalize_components(config.components)
	validate_components(components)
	const rules = collect_rules(components)

	const diagnostics = config.diagnostics or { minimum_failure_severity = "error" }
	if typeof(diagnostics) ~= "table" then
		error("kern: project diagnostics must be a table", 2)
	end
	if typeof(diagnostics.minimum_failure_severity) ~= "string" then
		error("kern: diagnostics minimum_failure_severity must be a severity string", 2)
	end

	return {
		kind = "project",
		config = {
			root = root,
			entries = validate_entries(root, config.entries),
			include = validate_patterns(root, "include", config.include or { "**/*.luau", "**/*.lua" }),
			exclude = validate_patterns(root, "exclude", config.exclude or {}),
			components = components,
			lint_rules = rules.lint_rules,
			lint_components = rules.lint_components,
			transform_rules = rules.transform_rules,
			require_resolver = rules.require_resolver,
			output = config.output or rules.output,
			diagnostics = {
				minimum_failure_severity = validate_severity(diagnostics.minimum_failure_severity),
			},
			file_system = config.file_system or default_file_system,
		},
		lint = project_lint.run,
		transform = project_transform.run,
		build = project_build.run,
		check = function(self)
			return project_build.run(self, { write = false })
		end,
	}
end

project.new = new

return project
