

local function main_entry(xml_doc)
	Log.info("router_svr main_entry")

	require "router_svr.net_event_handler"
	require "router_svr.msg_handler"
	require "router_svr.rpc_handler"

	local UserMgr = require "router_svr.user_mgr"
	g_user_mgr = UserMgr.new()

end

return main_entry
