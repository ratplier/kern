--!strict

const types = require("@kern/syntax/types")

const location = {}

const function line_offsets(source: string): { number }
	const offsets = { 1 }

	for index = 1, #source do
		if source:sub(index, index) == "\n" then
			table.insert(offsets, index + 1)
		end
	end

	return offsets
end

function location.from_offset(source: string, offset: number): types.SourceLocation
	const offsets = line_offsets(source)
	local line = 1

	for index, line_offset in offsets do
		if line_offset > offset + 1 then
			break
		end

		line = index
	end

	return {
		line = line,
		column = offset - offsets[line] + 2,
	}
end

function location.offset_from_line_column(source: string, line: number, column: number): number
	const offsets = line_offsets(source)
	const line_offset = offsets[line] or (#source + 1)

	return line_offset + column - 2
end

function location.from_span(source: string, span: types.Span): types.SourceLocation
	return location.from_offset(source, span.start)
end

return location
