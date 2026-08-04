--!strict

const types = require("@kern/syntax/types")

export type Replacement = {
	owner_kind: "lint_fix" | "transform" | "require",
	owner_name: string,
	span: types.Span,
	source: string,
}

export type ReplacementError = {
	code: "replacement_conflict",
	message: string,
}

const replacement = {}

const function ordered_replacements(replacements: { Replacement }): { Replacement }
	const ordered = {}
	const used = {}

	while #ordered < #replacements do
		local best_index: number? = nil
		for index, value in replacements do
			if used[index] then
				continue
			end
			if best_index == nil then
				best_index = index
				continue
			end

			const best = replacements[best_index]
			if value.span.start > best.span.start or value.span.start == best.span.start and index > best_index then
				best_index = index
			end
		end

		if best_index == nil then
			break
		end
		used[best_index] = true
		table.insert(ordered, replacements[best_index])
	end

	return ordered
end

function replacement.validate(replacements: { Replacement }): { ok: true } | { ok: false, error: ReplacementError }
	const ordered = ordered_replacements(replacements)

	for index, current in ordered do
		if current.span.start < 0 or current.span.finish < current.span.start then
			return {
				ok = false,
				error = {
					code = "replacement_conflict",
					message = `invalid replacement span for {current.owner_name}`,
				},
			}
		end
	end

	for index = 1, #ordered - 1 do
		const current = ordered[index]
		const previous = ordered[index + 1]

		if current.span.start < previous.span.finish then
			return {
				ok = false,
				error = {
					code = "replacement_conflict",
					message = `{current.owner_name} overlaps {previous.owner_name}`,
				},
			}
		end
	end

	return { ok = true }
end

function replacement.apply(
	source: string,
	replacements: { Replacement }
): { ok: true, source: string } | { ok: false, error: ReplacementError }
	const validation = replacement.validate(replacements)

	if not validation.ok then
		return validation
	end

	const ordered = ordered_replacements(replacements)
	local output = source

	for _, current in ordered do
		if current.span.finish > #source then
			return {
				ok = false,
				error = {
					code = "replacement_conflict",
					message = `replacement {current.owner_name} exceeds source length`,
				},
			}
		end

		output = output:sub(1, current.span.start) .. current.source .. output:sub(current.span.finish + 1)
	end

	return {
		ok = true,
		source = output,
	}
end

return replacement
