--!strict

const kern = require("@kern")
const helpers = require("../helpers/project")
const test_types = require("../test")

return function(test: test_types.Test)
	test.describe("require resolution and output", function()
		test.it("resolves aliases, index modules, and relative output paths", function()
			const file_system = helpers.file_system({
				["src/main.luau"] = "return require(\"@shared\")",
				["src/shared/init.luau"] = "return {}",
			})
			const resolver = kern.require({ aliases = { ["@shared"] = "src/shared" } })
			const resolved = resolver:resolve("src/main.luau", "@shared", file_system, ".")
			if not resolved.ok then
				error(resolved.error.message)
			end
			test.assert_eq(resolved.value, "src/shared/init.luau")
			test.assert_eq(resolver:rewrite("src/main.luau", resolved.value, "@shared"), "./shared")
		end)

		test.it("reports unknown aliases and ambiguous modules", function()
			const resolver = kern.require({ aliases = { ["@shared"] = "src/shared" } })
			const missing = resolver:resolve("src/main.luau", "@missing/value", helpers.file_system({}), ".")
			if missing.ok then
				error("expected unknown alias")
			end
			test.assert_eq(missing.error.code, "unknown_alias")

			const ambiguous = resolver:resolve("src/main.luau", "@shared/value", helpers.file_system({
				["src/shared/value.luau"] = "return 1",
				["src/shared/value.lua"] = "return 1",
			}), ".")
			if ambiguous.ok then
				error("expected ambiguous module")
			end
			test.assert_eq(ambiguous.error.code, "ambiguous_module")
		end)

		test.it("copies selected folders and artifacts while excluding specs", function()
			const file_system = helpers.file_system({
				["src/main.luau"] = "original",
				["src/shared/config.luau"] = "return {}",
				["src/shared/config.spec.luau"] = "return true",
				["default.project.json"] = "{}",
			})
			const emitter = kern.output.directory({
				path = "out",
				include = { "src", "default.project.json" },
				exclude = { "src/**/*.spec.luau" },
			})
			const emitted = emitter:emit({
				{ file_path = "src/main.luau", source = "transformed" },
			}, file_system, ".")
			if not emitted.ok then
				error(emitted.error.message)
			end
			test.assert_eq(emitted.files_written, 3)
			test.assert_eq(file_system:read_file("out/src/main.luau").value, "transformed")
			test.assert(file_system:is_file("out/src/shared/config.luau"))
			test.assert(file_system:is_file("out/default.project.json"))
			test.assert(not file_system:is_file("out/src/shared/config.spec.luau"))
		end)
	end)
end
