const kern = require("@kern")

return kern.component("repository_output", {
	kern.output.directory({
		path = "generated",
		include = {
			"docs/api/api.json",
			"docs/api/authoring.md",
			"docs/api/core-and-cli.md",
			"docs/api/index.md",
			"docs/api/projects-and-output.md",
			"docs/api/syntax-and-queries.md",
			"src/cli/gen/modules.luau",
			"src/cli/gen/types.luau",
		},
	}),
})
