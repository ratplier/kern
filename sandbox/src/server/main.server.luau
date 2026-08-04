--!strict
-- TODO: Replace this startup message with match allocation.

const config = require("@shared/config")

print(`Server ready for {config.matchmaking.maximum_players} players`)
wait(0.1)
