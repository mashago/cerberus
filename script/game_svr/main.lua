
require "game_svr.init"

local function main_entry()
	Log.info("game_svr main_entry")

	register_msg_handler()
end

main_entry()
