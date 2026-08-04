--!strict

const component_types = require("@kern/component")
const file_system_types = require("@kern/fs/types")
const lint_types = require("@kern/lint/types")
const transform_types = require("@kern/transform")
const errors = require("@kern/core/errors")
const require_types = require("@kern/require")
const output_types = require("@kern/output")
const graph_types = require("@kern/core/graph")

export type DiagnosticPolicy = {
	minimum_failure_severity: lint_types.Severity,
}

export type ProjectConfig = {
	root: string?,
	entries: { string },
	include: { string }?,
	exclude: { string }?,
	components: { component_types.Component | component_types.ComponentMember },
	file_system: file_system_types.Filesystem?,
	output: output_types.OutputEmitter?,
	diagnostics: DiagnosticPolicy?,
}

export type InternalProjectConfig = {
	root: string,
	entries: { string },
	include: { string },
	exclude: { string },
	components: { component_types.Component },
	lint_rules: { lint_types.LintRule },
	lint_components: { [string]: string },
	transform_rules: {
		syntax: { transform_types.TransformRule },
		module: { transform_types.TransformRule },
		finalize: { transform_types.TransformRule },
	},
	require_resolver: require_types.RequireResolver?,
	output: output_types.OutputEmitter?,
	diagnostics: DiagnosticPolicy,
	file_system: file_system_types.Filesystem,
}

export type LintResult = {
	ok: boolean,
	files_processed: number,
	files_changed: number,
	diagnostics: { lint_types.Diagnostic },
	errors: { errors.ProcessingError },
	duration_milliseconds: number,
}

export type LintOptions = {
	fix: boolean?,
	paths: { string }?,
}

export type TransformedFile = {
	file_path: string,
	source: string,
	changed: boolean,
}

export type TransformOptions = {
	phases: { transform_types.TransformPhase }?,
	paths: { string }?,
	sources: { [string]: string }?,
	resolved_requires: { [string]: { require_types.ResolvedRequire } }?,
	write: boolean?,
	rewrite_requires: boolean?,
}

export type TransformResult = {
	ok: boolean,
	files_processed: number,
	files_changed: number,
	files_written: number,
	files: { TransformedFile },
	diagnostics: { lint_types.Diagnostic },
	errors: { errors.ProcessingError },
	duration_milliseconds: number,
}

export type BuildOutput = {
	source_path: string,
	output_path: string,
}

export type BuildResult = {
	ok: boolean,
	files_processed: number,
	files_changed: number,
	files_written: number,
	diagnostics: { lint_types.Diagnostic },
	errors: { errors.ProcessingError },
	graph: graph_types.ModuleGraph?,
	outputs: { BuildOutput },
	duration_milliseconds: number,
}

export type Project = {
	kind: "project",
	config: InternalProjectConfig,
	lint: (self: Project, options: LintOptions?) -> LintResult,
	transform: (self: Project, options: TransformOptions?) -> TransformResult,
	build: (self: Project, options: { write: boolean }?) -> BuildResult,
	check: (self: Project) -> BuildResult,
}

return nil
