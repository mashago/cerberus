

local function main_entry(xml_doc)
	Log.info("master_svr main_entry")

	require "master_svr.net_event_handler"
	require "master_svr.msg_handler"
	require "master_svr.rpc_handler"
	
	local ServerMgr = require "master_svr.server_mgr"
	g_server_mgr = ServerMgr.new()
end

return main_entry
