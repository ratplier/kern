--!strict

const kern = require("@kern")
const helpers = require("../helpers/project")
const test_types = require("../test")
const query_types = require("@kern/query/types")
const transform_types = require("@kern/transform")

const function logger_transform()
	return kern.transform("print_to_logger", {
		run = function(tree: query_types.SyntaxRoot, context: transform_types.TransformContext)
			if context.file_path:match("logger%.luau$") ~= nil then
				return
			end
			const calls = kern.calls.global("print"):collect(tree)
			if #calls == 0 then
				return
			end
			context:ensure_import("logger", "@shared/logger")
			for _, call in calls do
				if call.callee_node ~= nil then
					context:replace(call.callee_node, kern.quote_expression("logger.info"))
				end
			end
		end,
	})
end

return function(test: test_types.Test)
	test.describe("project pipeline", function()
		test.it("applies node transforms and rewrites generated imports", function()
			const project = helpers.project({
				["src/main.luau"] = "print(\"ready\")\nwait()",
				["src/shared/logger.luau"] = "return {}",
			}, { 
				logger_transform(),
				kern.transform("modernize_wait", {
					run = function(tree: query_types.SyntaxRoot, context: transform_types.TransformContext)
						for _, call in kern.calls.global("wait"):collect(tree) do
							if call.callee_node ~= nil then
								context:replace(call.callee_node, kern.quote_expression("task.wait"))
							end
						end
					end,
				}),
				kern.require({ aliases = { ["@shared"] = "src/shared" } }),
			}, { "src/main.luau" })

			const result = project:transform()
			test.assert(result.ok)
			const source = helpers.source(result, "src/main.luau")
			if source == nil then
				error("transformed main source was missing")
			end
			test.assert(source:find('const logger = require("./shared/logger")', 1, true) ~= nil)
			test.assert(source:find('logger.info("ready")', 1, true) ~= nil)
			test.assert(source:find("task.wait()", 1, true) ~= nil)
		end)

		test.it("applies lint fixes and leaves no unresolved diagnostics", function()
			const file_system = helpers.file_system({
				["src/main.luau"] = "-- TODO: ship feature\nreturn true",
			})
			const todo_fix = kern.lint("todo_fix", {
				run = function(tree, context)
					for comment in kern.comments.todo:visit(tree) do
						context:report(comment.span, "Resolve TODO", {
							fix = { span = comment.span, replacement = "-- DONE: ship feature" },
						})
					end
				end,
			})
			const project = kern.project({
				root = ".",
				entries = { "src/main.luau" },
				components = { todo_fix },
				file_system = file_system,
			})

			const fixed = project:lint({ fix = true })
			test.assert(fixed.ok)
			test.assert_eq(fixed.files_changed, 1)
			test.assert_eq(file_system:read_file("src/main.luau").value, "-- DONE: ship feature\nreturn true")
			test.assert_eq(#project:lint().diagnostics, 0)
		end)

		test.it("builds a reachable module graph and copies selected artifacts", function()
			const project = helpers.project({
				["src/server/main.luau"] = "return require(\"@shared/config\")",
				["src/shared/config.luau"] = "return { players = 12 }",
				["src/shared/config.spec.luau"] = "return true",
				["default.project.json"] = "{\"name\":\"TestGame\"}",
			}, { 
				kern.require({ aliases = { ["@shared"] = "src/shared" } }),
				kern.output.directory({
					path = "out",
					include = { "src", "default.project.json" },
					exclude = { "src/**/*.spec.luau" },
				}),
			}, { "src/server/main.luau" })

			const built = project:build()
			test.assert(built.ok)
			test.assert_eq(built.files_written, 3)
			const file_system = project.config.file_system
			const main = file_system:read_file("out/src/server/main.luau")
			test.assert(main.ok)
			test.assert(main.value:find('require("../shared/config")', 1, true) ~= nil)
			test.assert(file_system:is_file("out/default.project.json"))
			test.assert(not file_system:is_file("out/src/shared/config.spec.luau"))
		end)

		test.it("contains a failing transform and discards its pending edits", function()
			const project = helpers.project({
				["src/main.luau"] = "return true",
			}, {
				kern.transform("broken", {
					run = function(_: query_types.SyntaxRoot, context: transform_types.TransformContext)
						context:replace_range({ start = 0, finish = 0 }, "-- partial edit\n")
						error("intentional failure")
						return
					end,
				}),
			}, { "src/main.luau" })

			const result = project:transform()
			test.assert(not result.ok)
			test.assert_eq(result.errors[1].code, "rule_error")
			test.assert_eq(helpers.source(result, "src/main.luau"), "return true")
		end)

		test.it("stops builds that contain a module cycle", function()
			const project = helpers.project({
				["src/main.luau"] = "return require(\"./a\")",
				["src/a.luau"] = "return require(\"./b\")",
				["src/b.luau"] = "return require(\"./a\")",
			}, {
				kern.output.directory({ path = "out", source_root = "src" }),
			}, { "src/main.luau" })

			const built = project:build()
			test.assert(not built.ok)
			test.assert_eq(built.errors[1].code, "module_cycle")
		end)
	end)
end
