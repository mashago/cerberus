
require "router_svr.msg_handler"
require "router_svr.rpc_handler"

local function main_entry()
	Log.info("router_svr main_entry")

	register_msg_handler()
	register_rpc_handler()

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	-- load ip and port
	g_funcs.load_address(xml_doc)

end

main_entry()
