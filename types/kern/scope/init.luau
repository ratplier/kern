--!nocheck

const Result = require("@kern/core/result")
const Syntax = require("@kern/syntax/types")

--[=[
	@within Scope

	How a source directive selects the code it suppresses.
]=]
export type ScopeBinding = "next" | "range" | "range_end" | "file"

--[=[
	@within Scope

	Configures comment directives for a lint or transform namespace.
]=]
export type ScopeConfig = {
	namespace: string,
	directives: { [string]: ScopeBinding },
}

export type Scope = ScopeConfig

--[=[
	@within Scope

	A source range suppressed by a scope directive.
]=]
export type Suppression = { namespace: string, start: number, finish: number }

--[=[
	@within Scope

	Parsed suppressions for one source file.
]=]
export type ScopeMap = {
	suppressions: { Suppression },
	is_suppressed: (self: ScopeMap, namespace: string, span: Syntax.Span) -> boolean,
}

--[=[
	@within Scope

	A malformed or misplaced scope directive.
]=]
export type ScopeError = { code: "scope_error", message: string, span: Syntax.Span? }

local scope = {}

--[=[
	@within Scope

	Creates a comment-directive scope.

	@param config The directive namespace and binding names
	@return The configured scope
]=]
function scope.new(config: ScopeConfig): Scope
	return nil :: any
end

--[=[
	@within Scope

	Parses all configured directives in a source file.

	@param source The source containing directives
	@param value The scope configuration to apply
	@return The suppression map or a structured scope error
]=]
function scope.parse(source: string, value: Scope): Result.Result<ScopeMap, ScopeError>
	return nil :: any
end

return scope
