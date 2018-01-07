

local function main_entry()
	Log.info("master_svr main_entry")

	require "master_svr.net_event_handler"
	require "master_svr.msg_handler"
	require "master_svr.rpc_handler"

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end
	
	local ServerMgr = require "master_svr.server_mgr"
	g_server_mgr = ServerMgr.new()
end

return main_entry
