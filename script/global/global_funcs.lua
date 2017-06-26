
g_funcs = {}

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
		Log.err("tinyxml scene_list_ele nil %s", g_conf_file)
		return false
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

function g_handle_register_server(data, mailbox_id, msg_id)
	Log.debug("handle_register_server: data=%s", Util.TableToString(data))

	-- check mailbox is trust
	-- add into server list
	-- send other server list to server
	-- broadcast to other server
	
	local mailbox = Net.get_mailbox(mailbox_id)
	if not mailbox then
		Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, ServerErrorCode.REGISTER_FAIL, 0, 0)
		return
	end

	if mailbox.conn_type ~= ConnType.TRUST then
		Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, ServerErrorCode.REGISTER_UNTRUST, 0, 0)
		return
	end

	-- add server
	ServiceServer.add_server(mailbox_id, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)

	Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, ServerErrorCode.SUCCESS, ServerConfig._server_id, ServerConfig._server_type)

	-- broadcast
	for server_id, server_info in pairs(ServiceServer._all_server_map) do
		if server_id ~= data.server_id then
			Net.send_msg(server_info._mailbox_id, MID.REGISTER_SERVER_BROADCAST, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)
			Net.send_msg(mailbox_id, MID.REGISTER_SERVER_BROADCAST, server_info._server_id, server_info._server_type, server_info._single_scene_list, server_info._from_to_scene_list)
		end
	end

end

return g_funcs
