const kern = require("@kern")

const quality = require("./tooling/components/quality")
const repository_output = require("./tooling/components/repository_output")

return kern.project({
	root = ".",
	entries = { "src/kern/core/result.luau" },
	include = { "**/*.luau" },
	exclude = {
		"generated/**/*.luau",
		"sandbox/out/**/*.luau",
	},
	components = {
		quality,
		repository_output,
	},
})
