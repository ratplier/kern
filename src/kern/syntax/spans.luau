--!strict

const types = require("@kern/syntax/types")

type LuteLocation = {
	beginLine: number,
	beginColumn: number,
	endLine: number,
	endColumn: number,
}

const spans = {}

function spans.from_location(location: LuteLocation): types.Span
	return {
		start = location.beginColumn,
		finish = location.endColumn,
	}
end

function spans.contains(container: types.Span, value: types.Span): boolean
	return container.start <= value.start and container.finish >= value.finish
end

function spans.overlaps(first: types.Span, second: types.Span): boolean
	return first.start < second.finish and second.start < first.finish
end

return spans
