--!strict

const errors = require("@kern/core/errors")

local exit_code = {}

function exit_code.from_errors(error_values: { errors.ProcessingError }): number
	for _, value in error_values do
		if value.code == "filesystem_error" or value.code == "output_error" then
			return 4
		end
		if value.code == "invalid_entry" then
			return 3
		end
	end

	return 2
end

return exit_code
