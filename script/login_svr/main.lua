
require "login_svr.net_event_handler"

local function main_entry()
	Log.info("login_svr main_entry")

	require "login_svr.msg_handler"

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	-- connect to other server
	g_funcs.connect_to_servers(xml_doc)

	local AreaMgr = require "login_svr.area_mgr"
	g_area_mgr = AreaMgr.new()

	local UserMgr = require "login_svr.user_mgr"
	g_user_mgr = UserMgr.new()

end

main_entry()
