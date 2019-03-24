
local Log = require "log.logger"
local Env = require "env"

require "login_svr.net_event_handler"
require "login_svr.msg_handler"

local function main_entry()
	Log.info("login_svr main_entry")

	local AreaMgr = require "login_svr.area_mgr"
	Env.area_mgr = AreaMgr.new()

	local UserMgr = require "login_svr.user_mgr"
	Env.user_mgr = UserMgr.new()

end

return main_entry
