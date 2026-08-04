const kern = require("@kern")

return kern.component("production_output", {
	kern.require({
		aliases = {
			["@shared"] = "src/shared",
		},
	}),
	kern.output.directory({
		path = "out",
		include = {
			"src",
			"default.project.json",
		},
		exclude = {
			"src/**/*.spec.luau",
			"src/**/.luaurc",
		},
	}),
})
