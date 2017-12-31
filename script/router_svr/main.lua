

local function main_entry()
	Log.info("router_svr main_entry")

	require "router_svr.net_event_handler"
	require "router_svr.msg_handler"
	require "router_svr.rpc_handler"

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	-- load ip and port
	g_funcs.load_address(xml_doc)

	-- connect to other server
	g_funcs.connect_to_servers(xml_doc)

	local UserMgr = require "router_svr.user_mgr"
	g_user_mgr = UserMgr.new()

end

return main_entry
