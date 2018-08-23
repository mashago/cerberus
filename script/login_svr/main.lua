
local Log = require "core.log.logger"

local function main_entry(xml_doc)
	Log.info("login_svr main_entry")

	require "login_svr.net_event_handler"
	require "login_svr.msg_handler"

	local AreaMgr = require "login_svr.area_mgr"
	g_area_mgr = AreaMgr.new()

	local UserMgr = require "login_svr.user_mgr"
	g_user_mgr = UserMgr.new()

end

return main_entry
