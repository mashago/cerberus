

local function main_entry(xml_doc)
	Log.info("bridge_svr main_entry")

	require "bridge_svr.msg_handler"
	require "bridge_svr.rpc_handler"

	g_funcs.load_scene(xml_doc)
	g_funcs.load_area(xml_doc)

end

return main_entry
