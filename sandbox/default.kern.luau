const kern = require("@kern")

const quality = require("./components/quality")
const migrations = require("./components/migrations")
const production_output = require("./components/production_output")

return kern.project({
	root = ".",
	entries = {
		"src/server/main.server.luau",
		"src/client/main.client.luau",
	},
	include = { "src/**/*.luau", "src/*.luau" },
	components = {
		quality,
		migrations,
		production_output,
	},
})
