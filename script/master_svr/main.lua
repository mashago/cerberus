

local function main_entry(xml_doc)
	Log.info("master_svr main_entry")

	require "master_svr.net_event_handler"
	require "master_svr.msg_handler"
	require "master_svr.rpc_handler"
	
	local PeerMgr = require "master_svr.peer_mgr"
	g_peer_mgr = PeerMgr.new()
end

return main_entry
