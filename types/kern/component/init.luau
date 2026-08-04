--!nocheck

const Lint = require("@kern/lint")
const Transform = require("@kern/transform")
const Require = require("@kern/require")
const Output = require("@kern/output")

export type MemberKind = "lint" | "transform" | "require" | "output"
export type ComponentMember = Lint.LintRule | Transform.TransformRule | Require.RequireResolver | Output.OutputEmitter

--[=[
	@within Component

	A named group of rules and project services that can be reused together.
]=]
export type Component = {
	kind: "component",
	name: string,
	members: { ComponentMember },
}

local component = {}

--[=[
	@within Component

	Groups related lint rules, transforms, require resolvers, and output emitters.

	@param name A unique name for the component
	@param members Rules and project services included in the component
	@return The reusable component
]=]
function component.new(name: string, members: { ComponentMember }): Component
	return nil :: any
end

return component
