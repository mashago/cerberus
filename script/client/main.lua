

local function load_server_list(xml_doc)
	-- init server list
	local root_ele = xml_doc:first_child_element()
	if not root_ele then
		Log.err("tinyxml root_ele nil %s", g_conf_file)
		return false
	end

	local server_list_ele = root_ele:first_child_element("server_list")
	if not server_list_ele then
		Log.err("tinyxml server_list_ele nil %s", g_conf_file)
		return false
	end

	local address_ele = server_list_ele:first_child_element("address")
	while address_ele do
		local ip = address_ele:string_attribute("ip")
		local port = address_ele:int_attribute("port")
		local server_id = address_ele:int_attribute("id")
		local server_type = address_ele:int_attribute("type")
		Log.info("ip=%s port=%d server_id=%d server_type=%d", ip, port, server_id, server_type)

		g_client._server_list[server_type] =
		{
			ip = ip,
			port = port,
			server_id = server_id,
		}

		address_ele = address_ele:next_sibling_element()
	end
end

local function main_entry()
	Log.info("client main_entry")

	local Client = require "client.client"
	g_client = Client.new()

	local TimeCounter = require "client.time_counter"
	g_time_counter = TimeCounter.new()

	require "client.msg_handler"
	require "client.stdin_handler"

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	g_funcs.connect_to_servers(xml_doc)

	load_server_list(xml_doc)
end

return main_entry
