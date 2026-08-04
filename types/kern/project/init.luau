--!nocheck

const Component = require("@kern/component")
const Errors = require("@kern/core/errors")
const Filesystem = require("@kern/fs/types")
const Graph = require("@kern/core/graph")
const Lint = require("@kern/lint")
const Output = require("@kern/output")
const Require = require("@kern/require")
const Transform = require("@kern/transform")

--[=[
	@within Project

	Controls which diagnostics make a project operation fail.
]=]
export type DiagnosticPolicy = { minimum_failure_severity: Lint.Severity }

--[=[
	@within Project

	Configures the source files and components managed by a project.
]=]
export type ProjectConfig = {
	root: string?,
	entries: { string },
	include: { string }?,
	exclude: { string }?,
	components: { Component.Component | Component.ComponentMember },
	file_system: Filesystem.Filesystem?,
	output: Output.OutputEmitter?,
	diagnostics: DiagnosticPolicy?,
}

--[=[
	@within Project

	The normalized configuration retained by a project.
]=]
export type InternalProjectConfig = {
	root: string,
	entries: { string },
	include: { string },
	exclude: { string },
	components: { Component.Component },
	lint_rules: { Lint.LintRule },
	lint_components: { [string]: string },
	transform_rules: {
		syntax: { Transform.TransformRule },
		module: { Transform.TransformRule },
		finalize: { Transform.TransformRule },
	},
	require_resolver: Require.RequireResolver?,
	output: Output.OutputEmitter?,
	diagnostics: DiagnosticPolicy,
	file_system: Filesystem.Filesystem,
}

export type LintOptions = { fix: boolean?, paths: { string }? }

--[=[
	@within Project

	The result of linting project files.
]=]
export type LintResult = {
	ok: boolean,
	files_processed: number,
	files_changed: number,
	diagnostics: { Lint.Diagnostic },
	errors: { Errors.ProcessingError },
	duration_milliseconds: number,
}

export type TransformedFile = { file_path: string, source: string, changed: boolean }

export type TransformOptions = {
	phases: { Transform.TransformPhase }?,
	paths: { string }?,
	sources: { [string]: string }?,
	resolved_requires: { [string]: { Require.ResolvedRequire } }?,
	write: boolean?,
	rewrite_requires: boolean?,
}

--[=[
	@within Project

	The result of transforming project files.
]=]
export type TransformResult = {
	ok: boolean,
	files_processed: number,
	files_changed: number,
	files_written: number,
	files: { TransformedFile },
	diagnostics: { Lint.Diagnostic },
	errors: { Errors.ProcessingError },
	duration_milliseconds: number,
}

export type BuildOutput = { source_path: string, output_path: string }

--[=[
	@within Project

	The result of building or checking a project.
]=]
export type BuildResult = {
	ok: boolean,
	files_processed: number,
	files_changed: number,
	files_written: number,
	diagnostics: { Lint.Diagnostic },
	errors: { Errors.ProcessingError },
	graph: Graph.ModuleGraph?,
	outputs: { BuildOutput },
	duration_milliseconds: number,
}

--[=[
	@within Project

	A configured kern project and its processing operations.
]=]
export type Project = {
	kind: "project",
	config: InternalProjectConfig,
	lint: (self: Project, options: LintOptions?) -> LintResult,
	transform: (self: Project, options: TransformOptions?) -> TransformResult,
	build: (self: Project, options: { write: boolean }?) -> BuildResult,
	check: (self: Project) -> BuildResult,
}

local project = {}

--[=[
	@within Project

	Creates a project from source paths and reusable components.

	@param config Source paths, components, filesystem, output, and diagnostic policy
	@return The configured project
]=]
function project.new(config: ProjectConfig): Project
	return nil :: any
end

return project
