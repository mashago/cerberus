
require "login_svr.area_mgr"
require "login_svr.user_mgr"
require "login_svr.msg_handler"
require "login_svr.net_event_handler"

local function main_entry()
	Log.info("login_svr main_entry")

	register_msg_handler()

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	-- connect to other server
	g_funcs.connect_to_servers(xml_doc)

end

main_entry()
