
require "client.msg_handler"
require "client.stdin_handler"

local function main_entry()
	Log.info("client main_entry")

	register_msg_handler()

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	g_funcs.connect_to_servers(xml_doc)

end

main_entry()
