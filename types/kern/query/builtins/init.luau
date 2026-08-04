--!nocheck

const Query = require("@kern/query/types")
const Calls = require("@kern/query/builtins/calls")

type Node = Query.SyntaxNode
type Span = Query.Span

--[=[
	@within Queries

	A normalized function parameter and its original syntax node.
]=]
export type FunctionParameter = { name: string?, raw: Node }

--[=[
	@within Queries

	Normalized metadata for a function declaration or expression.
]=]
export type FunctionInfo = {
	name: string?, is_local: boolean, is_method: boolean, parameter_count: number,
	parameters: { FunctionParameter }, has_return_type: boolean, has_variadic_parameter: boolean,
	body_statement_count: number, span: Span, raw: Node,
}
--[=[
	@within Queries

	Normalized metadata for a local binding.
]=]
export type LocalInfo = {
	name: string, has_annotation: boolean, has_value: boolean, is_const: boolean,
	annotation_name: string?, span: Span, raw: Node,
}
--[=[
	@within Queries

	Normalized metadata for a type annotation or declaration.
]=]
export type TypeInfo = { kind: string, name: string?, is_export: boolean, span: Span, raw: Node }

--[=[
	@within Queries

	Normalized metadata for a table constructor.
]=]
export type TableInfo = {
	entry_count: number, has_record_entries: boolean, has_array_entries: boolean,
	is_empty: boolean, span: Span, raw: Node,
}
--[=[
	@within Queries

	Normalized metadata for a branch, loop, return, or flow-control statement.
]=]
export type ControlFlowInfo = {
	kind: string, has_else: boolean?, is_early_return: boolean?, body_statement_count: number?,
	span: Span, raw: Node,
}
--[=[
	@within Queries

	Normalized metadata for a string expression.
]=]
export type StringInfo = {
	value: string?, is_interpolated: boolean, is_long_string: boolean, span: Span, raw: Node,
}
--[=[
	@within Queries

	Normalized metadata for a unary or binary operator expression.
]=]
export type OperatorInfo = { operator: string, is_binary: boolean, is_unary: boolean, span: Span, raw: Node }

--[=[
	@within Queries

	Normalized metadata for require calls and module returns.
]=]
export type ModuleInfo = {
	kind: "require" | "return", require_path: string?, return_value_count: number?,
	is_supported_require: boolean?, is_aliased: boolean?, alias: string?, argument_span: Span?,
	span: Span, raw: Node,
}
--[=[
	@within Queries

	Normalized comment metadata.

	`text` retains the raw comment while `content` removes comment delimiters and
	surrounding whitespace. Classification fields make documentation, pragmas,
	TODOs, and FIXMEs directly queryable.
]=]
export type CommentInfo = {
	text: string, content: string, is_multiline: boolean, is_pragma: boolean,
	is_documentation: boolean, is_todo: boolean, is_fixme: boolean, span: Span,
}

local catalog = {}

catalog.calls = Calls
catalog.functions = nil :: {
	any: Query.Query<FunctionInfo>, local_function: Query.Query<FunctionInfo>, anonymous: Query.Query<FunctionInfo>,
	variadic: Query.Query<FunctionInfo>, untyped: Query.Query<FunctionInfo>, typed: Query.Query<FunctionInfo>,
	no_parameters: Query.Query<FunctionInfo>, empty_body: Query.Query<FunctionInfo>,
	named: (name: string) -> Query.Query<FunctionInfo>,
	with_parameter_count: (count: number) -> Query.Query<FunctionInfo>,
	with_minimum_parameters: (minimum: number) -> Query.Query<FunctionInfo>,
	with_maximum_parameters: (maximum: number) -> Query.Query<FunctionInfo>,
	parameter_count_between: (minimum: number, maximum: number) -> Query.Query<FunctionInfo>,
	with_attribute: (attribute: string) -> Query.Query<FunctionInfo>,
	returning: (type_name: string) -> Query.Query<FunctionInfo>,
}
catalog.locals = nil :: {
	any: Query.Query<LocalInfo>, uninitialized: Query.Query<LocalInfo>, initialized: Query.Query<LocalInfo>,
	annotated: Query.Query<LocalInfo>, unannotated: Query.Query<LocalInfo>,
	constant: Query.Query<LocalInfo>, mutable: Query.Query<LocalInfo>,
	named: (name: string) -> Query.Query<LocalInfo>,
	annotated_with: (type_name: string) -> Query.Query<LocalInfo>,
}
catalog.types = nil :: {
	any: Query.Query<TypeInfo>, annotations: Query.Query<TypeInfo>, optional: Query.Query<TypeInfo>,
	unannotated_parameter: Query.Query<TypeInfo>, unannotated_return: Query.Query<TypeInfo>,
	reference: (name: string) -> Query.Query<TypeInfo>, alias: (name: string?) -> Query.Query<TypeInfo>,
	union_containing: (name: string) -> Query.Query<TypeInfo>,
}
catalog.tables = nil :: {
	any: Query.Query<TableInfo>, empty: Query.Query<TableInfo>, array_style: Query.Query<TableInfo>,
	record_style: Query.Query<TableInfo>, mixed: Query.Query<TableInfo>,
	with_key: (name: string) -> Query.Query<TableInfo>,
	with_minimum_entries: (minimum: number) -> Query.Query<TableInfo>,
	with_maximum_entries: (maximum: number) -> Query.Query<TableInfo>,
	with_entry_count: (count: number) -> Query.Query<TableInfo>,
	entry_count_between: (minimum: number, maximum: number) -> Query.Query<TableInfo>,
}
catalog.control_flow = nil :: {
	any_if: Query.Query<ControlFlowInfo>, any_loop: Query.Query<ControlFlowInfo>,
	numeric_for: Query.Query<ControlFlowInfo>, generic_for: Query.Query<ControlFlowInfo>,
	while_loop: Query.Query<ControlFlowInfo>, repeat_loop: Query.Query<ControlFlowInfo>,
	break_statement: Query.Query<ControlFlowInfo>, continue_statement: Query.Query<ControlFlowInfo>,
	early_return: Query.Query<ControlFlowInfo>, empty_body: Query.Query<ControlFlowInfo>,
	if_without_else: Query.Query<ControlFlowInfo>,
}
catalog.strings = nil :: {
	any: Query.Query<StringInfo>, plain: Query.Query<StringInfo>, interpolated: Query.Query<StringInfo>,
	concatenated: Query.Query<StringInfo>, empty: Query.Query<StringInfo>, non_empty: Query.Query<StringInfo>,
	long: Query.Query<StringInfo>, matching: (pattern: string) -> Query.Query<StringInfo>,
	equal_to: (expected: string) -> Query.Query<StringInfo>,
	containing: (expected: string) -> Query.Query<StringInfo>,
	starting_with: (prefix: string) -> Query.Query<StringInfo>,
	ending_with: (suffix: string) -> Query.Query<StringInfo>,
	with_minimum_length: (minimum: number) -> Query.Query<StringInfo>,
	with_maximum_length: (maximum: number) -> Query.Query<StringInfo>,
}
catalog.operators = nil :: {
	any_binary: Query.Query<OperatorInfo>, any_unary: Query.Query<OperatorInfo>,
	and_or_ternary: Query.Query<OperatorInfo>, binary: (operator: string?) -> Query.Query<OperatorInfo>,
	unary: (operator: string?) -> Query.Query<OperatorInfo>,
}
catalog.modules = nil :: {
	requires: Query.Query<ModuleInfo>, returns: Query.Query<ModuleInfo>,
	aliased_requires: Query.Query<ModuleInfo>, relative_requires: Query.Query<ModuleInfo>,
	unsupported_requires: Query.Query<ModuleInfo>, empty_returns: Query.Query<ModuleInfo>,
	require_path: (pattern: string) -> Query.Query<ModuleInfo>,
	require_path_equal_to: (expected: string) -> Query.Query<ModuleInfo>,
	require_alias: (alias: string) -> Query.Query<ModuleInfo>,
	with_return_value_count: (count: number) -> Query.Query<ModuleInfo>,
}
catalog.comments = nil :: {
	any: Query.Query<CommentInfo>, single_line: Query.Query<CommentInfo>, multiline: Query.Query<CommentInfo>,
	pragma: Query.Query<CommentInfo>, documentation: Query.Query<CommentInfo>, todo: Query.Query<CommentInfo>,
	fixme: Query.Query<CommentInfo>, empty: Query.Query<CommentInfo>,
	containing: (pattern: string) -> Query.Query<CommentInfo>,
	containing_text: (expected: string, ignore_case: boolean?) -> Query.Query<CommentInfo>,
	equal_to: (expected: string, ignore_case: boolean?) -> Query.Query<CommentInfo>,
	starting_with: (prefix: string, ignore_case: boolean?) -> Query.Query<CommentInfo>,
	ending_with: (suffix: string, ignore_case: boolean?) -> Query.Query<CommentInfo>,
	with_minimum_length: (minimum: number) -> Query.Query<CommentInfo>,
	with_maximum_length: (maximum: number) -> Query.Query<CommentInfo>,
}

return catalog
