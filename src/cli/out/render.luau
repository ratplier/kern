--!strict

const cli_types = require("@cli/types")

const errors = require("@kern/core/errors")
const lint_types = require("@kern/lint/types")

local render = {}

const function diagnostic_line(diagnostic: lint_types.Diagnostic): string
	return `{diagnostic.severity} {diagnostic.rule} at {diagnostic.file_path}:{diagnostic.line}:{diagnostic.column}: {diagnostic.message}`
end

const function error_line(error_value: errors.ProcessingError): string
	local location = ""
	if error_value.file_path ~= nil then
		location = ` at {error_value.file_path}`
		if error_value.line ~= nil and error_value.column ~= nil then
			location ..= `:{error_value.line}:{error_value.column}`
		end
	end

	return `error {error_value.code}{location}: {error_value.message}`
end

const function summary(value: cli_types.RunResult): string
	const details = value.value :: any
	if details.outputs ~= nil then
		return `{value.command}: processed {details.files_processed} files, changed {details.files_changed}, wrote {details.files_written}`
	end
	if details.files ~= nil then
		return `transform: processed {details.files_processed} files, changed {details.files_changed}, wrote {details.files_written}`
	end
	return `lint: processed {details.files_processed} files, changed {details.files_changed}`
end

function render.value(value: cli_types.RunResult): string
	const lines = {}
	for _, diagnostic in value.value.diagnostics do
		table.insert(lines, diagnostic_line(diagnostic))
		for _, note in diagnostic.notes do
			table.insert(lines, `  note: {note.message}`)
		end
		if diagnostic.fix ~= nil then
			table.insert(lines, "  fix available")
		end
	end

	for _, error_value in value.value.errors do
		table.insert(lines, error_line(error_value))
		for _, note in error_value.notes do
			table.insert(lines, `  note: {note}`)
		end
	end
	if #value.value.errors == 0 then
		table.insert(lines, summary(value))
	end

	return table.concat(lines, "\n")
end

return render
