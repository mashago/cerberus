
require "db_svr.msg_handler"
require "db_svr.rpc_handler"

local function main_entry()
	Log.info("db_svr main_entry")

	register_msg_handler()
	register_rpc_handler()

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	-- connect to other server
	-- g_funcs.connect_to_servers(xml_doc)

end

main_entry()
