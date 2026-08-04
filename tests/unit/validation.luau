--!strict

const kern = require("@kern")
const test_types = require("../test")

return function(test: test_types.Test)
	test.describe("configuration validation", function()
		test.it("rejects unsafe output paths", function()
			test.assert_error(function()
				kern.output.directory({ path = "../outside", include = { "src" } })
			end, "must remain inside")
		end)

		test.it("rejects missing output paths with a useful message", function()
			test.assert_error(function()
				kern.output.directory({ include = { "src" } } :: any)
			end, "output path must be a string")
		end)

		test.it("rejects malformed aliases", function()
			test.assert_error(function()
				kern.require({ aliases = { shared = "src/shared" } } :: any)
			end, "invalid require alias")
		end)

		test.it("rejects project roots outside the repository", function()
			test.assert_error(function()
				kern.project({
					root = "../outside",
					entries = { "src/main.luau" },
					components = {},
				} :: any)
			end, "project root must be a project-relative directory")
		end)
	end)
end
