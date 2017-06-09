
require "game_svr.init"

local function main_entry()
	Log.info("game_svr main_entry")

	register_msg_handler()

	Services.add_connect_service("127.0.0.1", 7711, "aaa")
	Services.create_connect_timer(2000)

	--[[
	local function timer_cb(arg)
		Log.info("timer_cb arg=%d", arg)
	end
	Timer.add_timer(1000, timer_cb, 10086, true)
	--]]
end

main_entry()
