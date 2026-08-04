--!strict

const replacement = require("@kern/syntax/replacement")
const scope = require("@kern/scope")
const test_types = require("../test")

return function(test: test_types.Test)
	test.describe("replacements and scoped rules", function()
		test.it("applies multiple replacements from right to left", function()
			const applied = replacement.apply("local value = 10", {
				{ owner_kind = "transform", owner_name = "rename", span = { start = 6, finish = 11 }, source = "score" },
				{ owner_kind = "transform", owner_name = "value", span = { start = 14, finish = 16 }, source = "40" },
			})
			if not applied.ok then
				error(applied.error.message)
			end
			test.assert_eq(applied.source, "local score = 40")
		end)

		test.it("rejects overlapping source edits", function()
			const applied = replacement.apply("local value = 10", {
				{ owner_kind = "transform", owner_name = "first", span = { start = 0, finish = 8 }, source = "const" },
				{ owner_kind = "transform", owner_name = "second", span = { start = 6, finish = 11 }, source = "score" },
			})
			if applied.ok then
				error("expected replacement conflict")
			end
			test.assert_eq(applied.error.code, "replacement_conflict")
		end)

		test.it("suppresses the statement immediately after a next directive", function()
			const configured = scope.new({ namespace = "kern", directives = { disable_next = "next" } })
			const parsed = scope.parse("-- kern: disable_next\nprint(\"ignored\")\nprint(\"reported\")", configured)
			if not parsed.ok then
				error(parsed.error.message)
			end
			test.assert(parsed.value:is_suppressed("kern", { start = 22, finish = 38 }))
			test.assert(not parsed.value:is_suppressed("kern", { start = 40, finish = 57 }))
		end)

		test.it("rejects a range end without a matching range", function()
			const configured = scope.new({ namespace = "kern", directives = { end_disable = "range_end" } })
			const parsed = scope.parse("-- kern: end_disable", configured)
			if parsed.ok then
				error("expected scope error")
			end
			test.assert_eq(parsed.error.code, "scope_error")
		end)
	end)
end
