--!strict

const common = require("@kern/query/builtins/common")
const query_types = require("@kern/query/types")

export type ControlFlowInfo = {
	kind: string,
	has_else: boolean?,
	is_early_return: boolean?,
	body_statement_count: number?,
	span: query_types.Span,
	raw: any,
}

local control_flow = {}

const function normalize(node: any): ControlFlowInfo
	const body = node.body or node.thenBlock
	return {
		kind = node.tag,
		has_else = node.elseBlock ~= nil,
		is_early_return = node.tag == "return",
		body_statement_count = if body ~= nil then #body.statements else nil,
		span = node.location,
		raw = node,
	}
end

const function tag(tag_name: string): query_types.Query<ControlFlowInfo>
	return common.tag(tag_name, normalize)
end

control_flow.any_if = tag("conditional")
control_flow.any_loop = common.any(normalize):where(function(value: ControlFlowInfo): boolean
	return value.kind == "while" or value.kind == "for" or value.kind == "forin" or value.kind == "repeat"
end)
control_flow.numeric_for = tag("for")
control_flow.generic_for = tag("forin")
control_flow.while_loop = tag("while")
control_flow.repeat_loop = tag("repeat")
control_flow.break_statement = tag("break")
control_flow.continue_statement = tag("continue")
control_flow.early_return = tag("return")
control_flow.empty_body = control_flow.any_loop:where(function(value: ControlFlowInfo): boolean
	return value.body_statement_count == 0
end)
control_flow.if_without_else = control_flow.any_if:where(function(value: ControlFlowInfo): boolean
	return value.has_else == false
end)

return control_flow
