--!strict

const lint_types = require("@kern/lint/types")
const transform_types = require("@kern/transform")
const require_types = require("@kern/require")
const output_types = require("@kern/output")

export type MemberKind = "lint" | "transform" | "require" | "output"

export type ComponentMember =
	lint_types.LintRule
	| transform_types.TransformRule
	| require_types.RequireResolver
	| output_types.OutputEmitter

export type Component = {
	kind: "component",
	name: string,
	members: { ComponentMember },
}

local component = {}

const function copy_members(name: string, members: { ComponentMember }): { ComponentMember }
	if #members == 0 then
		error(`kern: component '{name}' must contain at least one member`, 2)
	end

	const copied = {}
	const names = {}

	for _, member in members do
		if typeof(member) ~= "table" then
			error(`kern: component '{name}' contains an unknown member`, 2)
		end
		if
			member.kind ~= "lint"
			and member.kind ~= "transform"
			and member.kind ~= "require"
			and member.kind ~= "output"
		then
			error(`kern: component '{name}' contains an unknown member kind`, 2)
		end
		if member.name == "" then
			error(`kern: component '{name}' contains a member with an empty name`, 2)
		end

		const key = `{member.kind}:{member.name}`
		if names[key] then
			error(`kern: component '{name}' contains duplicate member '{member.name}'`, 2)
		end

		names[key] = true
		table.insert(copied, table.clone(member))
	end

	return copied
end

const function new(name: string, members: { ComponentMember }): Component
	if name == "" then
		error("kern: component name cannot be empty", 2)
	end

	return {
		kind = "component",
		name = name,
		members = copy_members(name, members),
	}
end

component.new = new

return component
