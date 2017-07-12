
g_funcs = {}

function g_funcs.load_address(xml_doc)
	local root_ele = xml_doc:first_child_element()
	if not root_ele then
		Log.err("tinyxml root_ele nil %s", g_conf_file)
		return false
	end

	local ip = root_ele:string_attribute("ip")
	local port = root_ele:int_attribute("port")
	Log.info("g_funcs.load_address ip=%s port=%d", ip, port)

	ServerConfig._ip = ip
	ServerConfig._port = port
end

function g_funcs.connect_to_servers(xml_doc)
	local root_ele = xml_doc:first_child_element()
	if not root_ele then
		Log.err("tinyxml root_ele nil %s", g_conf_file)
		return false
	end

	local connect_to_ele = root_ele:first_child_element("connect_to")
	if not connect_to_ele then
		Log.err("tinyxml connect_to_ele nil %s", g_conf_file)
		return false
	end

	local address_ele = connect_to_ele:first_child_element("address")
	while address_ele do
		local ip = address_ele:string_attribute("ip")
		local port = address_ele:int_attribute("port")
		local server_id = address_ele:int_attribute("id")
		local server_type = address_ele:int_attribute("type")
		local register = address_ele:int_attribute("register")
		Log.info("ip=%s port=%d server_id=%d server_type=%d register=%d", ip, port, server_id, server_type, register)
		ServiceClient.add_connect_service(ip, port, server_id, server_type, register)

		address_ele = address_ele:next_sibling_element()
	end
	ServiceClient.create_connect_timer()

	return true
end

function g_funcs.load_scene(xml_doc)
	local root_ele = xml_doc:first_child_element()
	if not root_ele then
		Log.err("tinyxml root_ele nil %s", g_conf_file)
		return false
	end

	local scene_list_ele = root_ele:first_child_element("scene_list")
	if not scene_list_ele then
		-- no secen is ok
		-- Log.err("tinyxml scene_list_ele nil %s", g_conf_file)
		return true
	end

	local scene_ele = scene_list_ele:first_child_element("scene")
	while scene_ele do
		local single = scene_ele:int_attribute("single")
		local from = scene_ele:int_attribute("from")
		local to = scene_ele:int_attribute("to")
		Log.debug("single=%d from=%d to=%d", single, from, to)

		if single > 0 then
			ServerConfig.add_single_scene(single)
		end
		if to > from then
			ServerConfig.add_from_to_scene(from, to)
		end

		scene_ele = scene_ele:next_sibling_element()
	end

	return true
end

function g_funcs.load_area(xml_doc)
	local root_ele = xml_doc:first_child_element()
	if not root_ele then
		Log.err("tinyxml root_ele nil %s", g_conf_file)
		return false
	end

	local area_list_ele = root_ele:first_child_element("area_list")
	if not area_list_ele then
		Log.err("tinyxml area_list_ele nil %s", g_conf_file)
		return false
	end

	local area_ele = area_list_ele:first_child_element("area")
	while area_ele do
		local id = area_ele:int_attribute("id")
		Log.debug("id=%d", id)

		if id > 0 then
			ServerConfig.add_area(id)
		end
		area_ele = area_ele:next_sibling_element()
	end

	return true
end

function g_funcs.connect_to_mysql(xml_doc)
	local root_ele = xml_doc:first_child_element()
	if not root_ele then
		Log.err("tinyxml root_ele nil %s", g_conf_file)
		return false
	end

	local mysql_ele = root_ele:first_child_element("mysql")
	if not mysql_ele then
		Log.err("tinyxml mysql_ele nil %s", g_conf_file)
		return false
	end

	local info_ele = mysql_ele:first_child_element("info")
	while info_ele do
		local ip = info_ele:string_attribute("ip")
		local port = info_ele:int_attribute("port")
		local username = info_ele:string_attribute("username")
		local password = info_ele:string_attribute("password")
		local db_name = info_ele:string_attribute("db_name")
		Log.info("ip=%s port=%d username=%s password=%s db_name=%s", ip, port, username, password, db_name)

		DBMgr.connect_to_mysql(ip, port, username, password, db_name)

		info_ele = info_ele:next_sibling_element()
	end
	ServiceClient.create_connect_timer()

	return true
end

-- a common handle for MID.REGISTER_SERVER_REQ
function g_funcs.handle_register_server(data, mailbox_id, msg_id)
	Log.debug("handle_register_server: data=%s", Util.table_to_string(data))

	-- add into server list
	-- send other server list to server
	-- broadcast to other server

	local msg = 
	{
		result = ErrorCode.SUCCESS,
		server_id = ServerConfig._server_id,
		server_type = ServerConfig._server_type,
	}

	-- add server
	local new_server_info = ServiceServer.add_server(mailbox_id, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)
	if not new_server_info then
		msg.result = ErrorCode.REGISTER_SERVER_FAIL
		Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, msg)
		return
	end

	new_server_info:send_msg(MID.REGISTER_SERVER_RET, msg)

	-- broadcast
	if ServerConfig._no_broadcast then
		return
	end

	for server_id, server_info in pairs(ServiceServer._all_server_map) do
		if server_id ~= data.server_id then
			local msg = 
			{
				server_id = data.server_id,
				server_type = data.server_type,
				single_scene_list = data.single_scene_list,
				from_to_scene_list = data.from_to_scene_list,
			}
			server_info:send_msg(MID.REGISTER_SERVER_BROADCAST, msg)

			local msg = 
			{
				server_id = server_info._server_id,
				server_type = server_info._server_type,
				single_scene_list = server_info._single_scene_list,
				from_to_scene_list = server_info._from_to_scene_list,
			}
			new_server_info:send_msg(MID.REGISTER_SERVER_BROADCAST, msg)
		end
	end

end

-- a common handle for MID.REGISTER_SERVER_RET
function g_funcs.handle_register_server_ret(data, mailbox_id, msg_id)
	Log.debug("handle_register_server_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.err("handle_register_server_ret: register fail %d", data.result)
		return
	end
	local server_id = data.server_id
	local server_type = data.server_type
	ServiceClient.register_success(mailbox_id, server_id, server_type)

	if server_type == ServerType.LOGIN and ServerConfig._server_type == ServerType.BRIDGE then
		-- register area
		local msg = 
		{
			area_list = ServerConfig._area_list,
		}

		Net.send_msg(mailbox_id, MID.REGISTER_AREA_REQ, msg)
	end
end

-- a common handle for MID.REGISTER_SERVER_BROADCAST
function g_funcs.handle_register_server_broadcast(data, mailbox_id, msg_id)
	Log.debug("handle_register_server_broadcast: data=%s", Util.table_to_string(data))
	ServiceClient.add_server(mailbox_id, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)
end

-- a common handle for MID.SERVER_DISCONNECT
function g_funcs.handle_server_disconnect(data, mailbox_id, msg_id)
	Log.debug("handle_server_disconnect: data=%s", Util.table_to_string(data))
	ServiceClient.remove_server(mailbox_id, data.server_id)
end

return g_funcs
