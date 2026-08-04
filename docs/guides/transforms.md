---
sidebar_position: 3
---

# Transforms

Transforms work on parsed syntax and collect edits before Kern applies them.
Use queries to find nodes, quote source to create replacement nodes, and use
`ensure_import` to add requires without duplicating them.

```luau
const migrate_print = kern.transform("migrate_print", {
	run = function(tree, context)
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
```

`replace` and `remove` require syntax nodes. This keeps normal transforms tied
to real AST locations. Use `replace_range` or `remove_range` only for deliberate
raw source edits. A throwing rule becomes a `rule_error`, and edits it added are
discarded.
