--!strict

local logger = {}

function logger.info(message: string)
	print(`[game] {message}`)
end

function logger.warn(message: string)
	print(`[game warning] {message}`)
end

return logger
