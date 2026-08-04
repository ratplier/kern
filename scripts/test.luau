--!strict

const stats = require("../tests/run")
if stats.failed > 0 then
	error(`kern tests failed: {stats.failed}`, 0)
end
