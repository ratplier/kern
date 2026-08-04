--!strict

const memory = require("@kern/fs/memory")
const path = require("@kern/core/path")
const test_types = require("../test")

return function(test: test_types.Test)
	test.describe("core path and memory filesystem", function()
		test.it("normalizes paths without escaping the project", function()
			test.assert_eq(path.normalize("src\\shared/../server/./main.luau"), "src/server/main.luau")
			test.assert_eq(path.join("src/server", "../shared", "config.luau"), "src/shared/config.luau")
			test.assert(path.is_inside("src", "src/shared/config.luau"))
			test.assert(not path.is_inside("src", "scripts/build.luau"))
		end)

		test.it("matches recursive globs and honors exclusions", function()
			const file_system = memory.new({
				["src/main.luau"] = "return nil",
				["src/shared/config.luau"] = "return {}",
				["src/shared/config.spec.luau"] = "return true",
				["assets/icon.png"] = "png",
			})
			const found = file_system:find({ "src/**/*" }, { "src/**/*.spec.luau" })
			if not found.ok then
				error(found.error.message)
			end
			test.assert_eq(found.value, { "src/main.luau", "src/shared/config.luau" })
		end)

		test.it("removes an entire generated directory", function()
			const file_system = memory.new({
				["out/server/main.luau"] = "return nil",
				["out/client/main.luau"] = "return nil",
				["src/main.luau"] = "return nil",
			})
			const removed = file_system:remove_directory("out")
			test.assert(removed.ok)
			test.assert(not file_system:is_file("out/server/main.luau"))
			test.assert(file_system:is_file("src/main.luau"))
		end)
	end)
end
