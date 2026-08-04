const kern = require("@kern")

const unfinished_work = kern.lint("unfinished_work", {
	description = "Keeps TODO and FIXME comments visible across Kern's own source tree",
	severity = "warn",
	run = function(tree, context)
		for comment in kern.comments.todo:visit(tree) do
			if comment.content:match("^%s*TODO") ~= nil or comment.content:match("^%s*FIXME") ~= nil then
				context:report(comment.span, `Unresolved work item: {comment.content}`)
			end
		end
	end,
})

return kern.component("repository_quality", {
	unfinished_work,
})
