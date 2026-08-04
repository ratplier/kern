const kern = require("@kern")

const print_to_logger = kern.transform("print_to_logger", {
	run = function(tree, context)
		if context.file_path:match("shared/logger%.luau$") ~= nil then
			return
		end

		const calls = kern.calls.global("print"):collect(tree)
		if #calls == 0 then
			return
		end

		context:ensure_import("logger", "@shared/logger")
		for _, call in calls do
			if call.callee_node ~= nil then
				context:replace(call.callee_node, kern.quote("logger.info"))
			end
		end
	end,
})

const modernize_wait = kern.transform("modernize_wait", {
	run = function(tree, context)
		for call in kern.calls.global("wait"):visit(tree) do
			if call.callee_node ~= nil then
				context:replace(call.callee_node, kern.quote_expression("task.wait"))
			end
		end
	end,
})

return kern.component("migrations", {
	print_to_logger,
	modernize_wait,
})
