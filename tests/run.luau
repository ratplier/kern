--!strict

const test = require("./test")

const suites = {
	require("./unit/path_and_memory"),
	require("./unit/syntax_and_queries"),
	require("./unit/require_and_output"),
	require("./unit/replacements_and_scope"),
	require("./unit/validation"),
	require("./integration/project_pipeline"),
}

const stop = test.run("kern")
for _, suite in suites do
	suite(test)
end

const stats = stop()
if stats.failed > 0 then
	error(`kern tests failed: {stats.failed}`, 0)
end

return stats
