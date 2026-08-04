const kern = require("@kern")

const unfinished_work = kern.lint("unfinished_work", {
	description = "Keeps TODO and FIXME comments visible before a release",
	severity = "warn",
	run = function(tree, context)
		for comment in kern.comments.todo:visit(tree) do
			context:report(comment.span, `Unresolved work item: {comment.content}`)
		end
	end,
})

const no_global_print = kern.lint("no_global_print", {
	description = "Encourages structured game logging outside the logger module",
	severity = "warn",
	run = function(tree, context)
		if context.file_path:match("shared/logger%.luau$") ~= nil then
			return
		end

		for call in kern.calls.global("print"):visit(tree) do
			context:report(call.span, "Use logger.info instead of print")
		end
	end,
})

return kern.component("quality", {
	unfinished_work,
	no_global_print,
})
