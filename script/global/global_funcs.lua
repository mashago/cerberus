
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

return g_funcs