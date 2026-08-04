--!nocheck

const Project = require("@kern/project")
const Component = require("@kern/component")
const Lint = require("@kern/lint")
const Output = require("@kern/output")
const QueryModule = require("@kern/query")
const Query = require("@kern/query/types")
const Compose = require("@kern/query/compose")
const Catalog = require("@kern/query/builtins")
const Require = require("@kern/require")
const Scope = require("@kern/scope")
const Syntax = require("@kern/syntax/types")
const Transform = require("@kern/transform")
const Calls = require("@kern/query/builtins/calls")

export type ProjectConfig = Project.ProjectConfig
export type Project = Project.Project
export type ComponentMember = Component.ComponentMember
export type Component = Component.Component
export type LintDefinition = Lint.LintDefinition
export type LintRule = Lint.LintRule
export type OutputConfig = Output.OutputConfig
export type OutputEmitter = Output.OutputEmitter
export type RequireConfig = Require.RequireConfig
export type RequireResolver = Require.RequireResolver
export type ScopeConfig = Scope.ScopeConfig
export type Scope = Scope.Scope
export type TransformDefinition = Transform.TransformDefinition
export type TransformRule = Transform.TransformRule
export type Query<Result> = Query.Query<Result>
export type QueryConfig<Result> = Query.QueryConfig<Result>

--[=[
	@within kern

	The severity assigned to a lint diagnostic.
]=]
export type Severity = "hint" | "info" | "warn" | "error"

--[=[
	@within kern

	A half-open byte range in Luau source.
]=]
export type Span = {
	start: number,
	finish: number,
}

--[=[
	@within kern

	A source edit that can repair a diagnostic.
]=]
export type DiagnosticFix = {
	span: Span,
	replacement: string,
}

--[=[
	@within kern

	Additional context attached to a diagnostic.
]=]
export type DiagnosticNote = {
	message: string,
	span: Span?,
}

--[=[
	@within kern

	A problem reported while kern processes a source file.
]=]
export type Diagnostic = {
	rule: string,
	component: string,
	severity: Severity,
	message: string,
	file_path: string,
	span: Span,
	line: number,
	column: number,
	notes: { DiagnosticNote },
	fix: DiagnosticFix?,
}

local kern = {}

--[=[
	@within kern

	Groups related lint rules, transforms, require resolvers, and output emitters.

	@param name A unique name for the component
	@param members Rules and services included in the component
	@return The reusable component
]=]
function kern.component(name: string, members: { ComponentMember }): Component
	return nil :: any
end

--[=[
	@within kern

	Creates a project that can lint, transform, check, or build Luau files.

	@param config Source paths, components, filesystem, and output settings
	@return The configured project
]=]
function kern.project(config: ProjectConfig): Project
	return nil :: any
end

--[=[
	@within kern

	Creates a named lint rule from a rule definition.

	@param name A unique rule name
	@param definition The rule callback, severity, scope, and description
	@return The validated lint rule
]=]
function kern.lint(name: string, definition: LintDefinition): LintRule
	return nil :: any
end

--[=[
	@within kern

	Creates a named source transform from a transform definition.

	@param name A unique transform name
	@param definition The transform callback, phase, and scope
	@return The validated transform
]=]
function kern.transform(name: string, definition: TransformDefinition): TransformRule
	return nil :: any
end

--[=[
	@within kern

	Creates the module resolver used to inspect and rewrite require calls.

	@param config Aliases and module resolution behavior
	@return The configured require resolver
]=]
function kern.require(config: RequireConfig): RequireResolver
	return nil :: any
end

--[=[
	@within kern

	Creates a comment-directive scope used to suppress rules or transforms.

	@param config The directive namespace and binding names
	@return The configured scope
]=]
function kern.scope(config: ScopeConfig): Scope
	return nil :: any
end

--[=[
	@within kern

	Creates a reusable syntax query from matchers and a normalizer.

	@param config Matchers and a function that normalizes matching nodes
	@return A reusable query of normalized results
]=]
function kern.query<Result>(config: QueryConfig<Result>): Query<Result>
	return nil :: any
end

--[=[
	@within kern

	Parses a complete Luau source file.

	@param source The Luau source to parse
	@param file_path Optional path included in parse errors
	@return The parsed syntax tree or a structured parse error
]=]
function kern.parse(source: string, file_path: string?): Syntax.ParseResult
	return nil :: any
end

--[=[
	@within kern

	Parses a sequence of Luau statements.

	@param source The Luau statements to parse
	@return The parsed syntax tree or a structured parse error
]=]
function kern.parse_block(source: string): Syntax.ParseResult
	return nil :: any
end

--[=[
	@within kern

	Parses one Luau expression.

	@param source The Luau expression to parse
	@return The parsed syntax tree or a structured parse error
]=]
function kern.parse_expression(source: string): Syntax.ParseResult
	return nil :: any
end

--[=[
	@within kern

	Creates a syntax node from Luau source. A single statement produces that
	statement node, multiple statements produce a block, and expression source
	produces an expression node.

	The returned node can be passed directly to transform operations such as
	`context:replace(target, kern.quote("local answer = 40"))`.

	Throws an error when `source` is empty or is not valid Luau.

	@param source The Luau statement, statements, or expression to quote
	@return The generated syntax node
]=]
function kern.quote(source: string): Syntax.SyntaxNode
	return nil :: any
end

--[=[
	@within kern

	Creates an expression node from Luau source.

	Throws an error when `source` is not exactly one valid Luau expression.

	@param source The Luau expression to quote
	@return The generated expression node
]=]
function kern.quote_expression(source: string): Syntax.SyntaxExpression
	return nil :: any
end

--[=[
	@within kern

	Creates a block node from a sequence of Luau statements.

	Throws an error when `source` is not valid Luau.

	@param source The Luau statements to quote
	@return The generated statement block
]=]
function kern.quote_block(source: string): Syntax.SyntaxRoot
	return nil :: any
end

--[=[
	@within kern

	Output emitter constructors, including `directory`.
]=]
kern.output = Output
--[=[
	@within kern

	Predicates for narrowing query results.
]=]
kern.filters = QueryModule.filters
--[=[
	@within kern

	Helpers for composing query matchers and normalizers.
]=]
kern.compose = Compose
--[=[
	@within kern

	Helpers for matching syntax nodes.
]=]
kern.match = QueryModule.match
--[=[
	@within kern

	Queries for function and method calls.
]=]
kern.calls = Calls
--[=[
	@within kern

	Queries for function declarations and expressions.
]=]
kern.functions = Catalog.functions
--[=[
	@within kern

	Queries for local declarations and references.
]=]
kern.locals = Catalog.locals
--[=[
	@within kern

	Queries for type declarations and annotations.
]=]
kern.types = Catalog.types
--[=[
	@within kern

	Queries for table constructors and fields.
]=]
kern.tables = Catalog.tables
--[=[
	@within kern

	Queries for branches, loops, and control-flow statements.
]=]
kern.control_flow = Catalog.control_flow
--[=[
	@within kern

	Queries for string expressions.
]=]
kern.strings = Catalog.strings
--[=[
	@within kern

	Queries for unary and binary operators.
]=]
kern.operators = Catalog.operators
--[=[
	@within kern

	Queries for module-related syntax.
]=]
kern.modules = Catalog.modules
--[=[
	@within kern

	Queries for source comments.
]=]
kern.comments = Catalog.comments

return kern
