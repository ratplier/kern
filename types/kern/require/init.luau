--!nocheck

const Result = require("@kern/core/result")
const Filesystem = require("@kern/fs/types")
const Syntax = require("@kern/syntax/types")

export type RequireRewriteMode = "relative"

--[=[
	@within Require

	Configures module aliases, candidate extensions, and require rewriting.
]=]
export type RequireConfig = {
	name: string?,
	aliases: { [string]: string },
	extensions: { string }?,
	index_names: { string }?,
	rewrite: RequireRewriteMode?,
	allow_relative: boolean?,
	allow_unaliased: boolean?,
}

export type RequireErrorCode =
	"parse_error" | "missing_module" | "ambiguous_module" | "unknown_alias" | "path_escape" | "unsupported_require"

--[=[
	@within Require

	A failure to inspect or resolve a require call.
]=]
export type RequireError = {
	code: RequireErrorCode,
	message: string,
	source_path: string?,
	request: string?,
}

--[=[
	@within Require

	A require call discovered in source.
]=]
export type RequireRequest = {
	request: string,
	span: Syntax.Span,
	argument_span: Syntax.Span,
}

--[=[
	@within Require

	A require call and its resolved source module.
]=]
export type ResolvedRequire = {
	request: string,
	source_path: string,
	resolved_path: string,
	output_path: string?,
	alias: string?,
	span: Syntax.Span,
	argument_span: Syntax.Span,
}

--[=[
	@within Require

	The resolver used while building a project's module graph.
]=]
export type RequireResolver = {
	kind: "require",
	name: string,
	aliases: { [string]: string },
	extensions: { string },
	index_names: { string },
	allow_relative: boolean,
	allow_unaliased: boolean,
	resolve: (self: RequireResolver, source_path: string, request: string, file_system: Filesystem.Filesystem, project_root: string) -> Result.Result<string, RequireError>,
	rewrite: (self: RequireResolver, source_path: string, destination_path: string, request: string) -> string,
}

local resolver = {}

--[=[
	@within Require

	Creates a module resolver.

	@param config Aliases, extensions, index names, and resolution behavior
	@return The configured module resolver
]=]
function resolver.new(config: RequireConfig): RequireResolver
	return nil :: any
end

--[=[
	@within Require

	Finds supported require calls in Luau source.

	@param source The Luau source to inspect
	@return The discovered require calls or a structured parse error
]=]
function resolver.scan(source: string): Result.Result<{ RequireRequest }, RequireError>
	return nil :: any
end

return resolver
