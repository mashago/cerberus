

local function main_entry()
	Log.info("bridge_svr main_entry")

	require "bridge_svr.msg_handler"
	require "bridge_svr.rpc_handler"

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	g_funcs.load_scene(xml_doc)
	g_funcs.load_area(xml_doc)

	-- connect to other server
	g_funcs.connect_to_servers(xml_doc)

end

main_entry()
