
g_funcs = {}

function g_funcs.debug_timer_cb()
	-- Log.debug("********* g_funcs.debug_timer_cb")
	-- g_rpc_mgr:print()
end

function g_funcs.load_address(xml_doc)
	local root_ele = xml_doc:first_child_element()
	if not root_ele then
		Log.err("tinyxml root_ele nil %s", g_conf_file)
		return false
	end

	local ip = root_ele:string_attribute("ip")
	local port = root_ele:int_attribute("port")
	Log.info("g_funcs.load_address ip=%s port=%d", ip, port)

	g_server_conf._ip = ip
	g_server_conf._port = port
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
		local no_reconnect = address_ele:int_attribute("no_reconnect")
		local no_delay = address_ele:int_attribute("no_delay")
		Log.info("ip=%s port=%d server_id=%d server_type=%d register=%d no_reconnect=%d no_delay=%d", ip, port, server_id, server_type, register, no_reconnect, no_delay)
		g_service_client:do_connect(ip, port, server_id, server_type, register, no_reconnect, no_delay)

		address_ele = address_ele:next_sibling_element()
	end

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
			g_server_conf:add_single_scene(single)
		end
		if to > from then
			g_server_conf:add_from_to_scene(from, to)
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
			g_server_conf:add_area(id)
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
		local db_type = info_ele:int_attribute("db_type")
		local db_suffix = info_ele:string_attribute("db_suffix") or ""
		Log.info("ip=%s port=%d username=%s password=%s db_name=%s db_type=%d db_suffix=%s", ip, port, username, password, db_name, db_type, db_suffix)

		local real_db_name = db_name .. db_suffix
		Log.info("real_db_name=%s", real_db_name)

		-- core logic
		local ret = DBMgr.connect_to_mysql(ip, port, username, password, real_db_name)
		if ret then
			g_server_conf._db_name_map[db_type] = real_db_name
		else
			Log.warn("g_funcs.connect_to_mysql fail ip=%s port=%d username=%s password=%s db_name=%s db_type=%d db_suffix=%s real_db_name=%s", ip, port, username, password, db_name, db_type, db_suffix, real_db_name)
		end

		info_ele = info_ele:next_sibling_element()
	end

	return true
end

--[[
-- a common handle for MID.REGISTER_SERVER_REQ
function g_funcs.handle_register_server(data, mailbox_id, msg_id)
	Log.debug("handle_register_server: data=%s", Util.table_to_string(data))

	-- add into server list
	-- send other server list to server
	-- broadcast to other server

	local msg = 
	{
		result = ErrorCode.SUCCESS,
		server_id = g_server_conf._server_id,
		server_type = g_server_conf._server_type,
	}

	-- add server
	local new_server_info = g_service_server:add_server(mailbox_id, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)
	if not new_server_info then
		msg.result = ErrorCode.REGISTER_SERVER_FAIL
		Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, msg)
		return
	end

	new_server_info:send_msg(MID.REGISTER_SERVER_RET, msg)
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
	g_service_client:register_success(mailbox_id, server_id, server_type)

	if server_type == ServerType.LOGIN and g_server_conf._server_type == ServerType.BRIDGE then
		-- register area
		local msg = 
		{
			area_list = g_server_conf._area_list,
		}

		Net.send_msg(mailbox_id, MID.REGISTER_AREA_REQ, msg)
	end
end
--]]

-- about shake hand
-- a common handle for MID.SHAKE_HAND_REQ
function g_funcs.handle_shake_hand_req(data, mailbox_id)

	local msg = 
	{
		result = ErrorCode.SUCCESS,
		server_id = g_server_conf._server_id,
		server_type = g_server_conf._server_type,
		single_scene_list = g_server_conf._single_scene_list
		from_to_scene_list = g_server_conf._from_to_scene_list,
	}

	-- add server
	local new_server_info = g_service_server:add_server(mailbox_id, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)
	if not new_server_info then
		msg.result = ErrorCode.SHAKE_HAND_FAIL
		Net.send_msg(mailbox_id, MID.SHAKE_HAND_RET, msg)
		return
	end

	new_server_info:send_msg(MID.SHAKE_HAND_RET, msg)
end

-- a common handle for MID.SHAKE_HAND_RET
function g_funcs.handle_shake_hand_ret(data, mailbox_id)
	if data.result ~= ErrorCode.SUCCESS then
		Log.err("handle_shake_hand_ret: fail %d", data.result)
		return
	end
	local server_id = data.server_id
	local server_type = data.server_type
	local single_scene_list = data.single_scene_list
	local from_to_scene_list = data.from_to_scene_list

	g_service_client:shake_hand_success(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	if server_type == ServerType.LOGIN and g_server_conf._server_type == ServerType.BRIDGE then
		-- register area
		local msg = 
		{
			area_list = g_server_conf._area_list,
		}

		Net.send_msg(mailbox_id, MID.REGISTER_AREA_REQ, msg)
	end
end

-- a common handle for MID.SHAKE_HAND_INVITE
function g_funcs.handle_shake_hand_invite(data, mailbox_id)
	local ip = data.ip
	local port = data.port
	local server_id = 0
	local server_type = 0
	local register = 1
	local no_reconnect = 0
	g_service_client:do_connect(ip, port, server_id, server_type, register, no_reconnect)
end
--

-------- for attr data and string convert

--[[
define attr container:
attr_table = 
{
	byte_attr_list = {},
	bool_attr_list = {},
	int_attr_list = {},
	float_attr_list = {},
	short_attr_list = {},
	int64_attr_list = {},
	string_attr_list = {},
	struct_attr_list = {},
}

attr_map = 
{
	role_id = 111,
	role_name = "masha",
	...
}
--]]

function g_funcs.get_empty_attr_table()
	return {
		byte_attr_list = {},
		bool_attr_list = {},
		int_attr_list = {},
		float_attr_list = {},
		short_attr_list = {},
		int64_attr_list = {},
		string_attr_list = {},
		struct_attr_list = {},
	}
end

-- g_funcs.str_to_value("123", _Int) ==> 123
-- g_funcs.str_to_value("{}", _Struct) ==> {}
function g_funcs.str_to_value(value_str, value_type)
	if not value_type then
		Log.warn("g_funcs.str_to_value value_type nil value_str=%s", value_str)
		return value_str
	end
	-- type cast
	if value_type == _String then
		return value_str
	end

	if value_type == _Bool then
		return value_str == "1" or value_str == "true"
	end

	if value_type == _Byte or value_type == _Int
	or value_type == _Float or value_type == _Short
	or value_type == _Int64 then
		return tonumber(value_str)
	end

	if value_type == _Struct then
		if value_str == "_Null" then
			return {}
		end
		return Util.unserialize(value_str)
	end

	Log.err("g_funcs.str_to_value unknow type %d", value_type)
	return value_str
end

-- set attr into attr_table
function g_funcs.set_attr_table(input_table, table_def, field_name, value)

	local field_def = table_def[field_name]
	if not field_def then
		Log.warn("g_funcs.set_attr_table field_def nil field_name=%s", field_name)
		return false
	end

	if value == nil then
		Log.warn("g_funcs.set_attr_table value nil field_name=%s", field_name)
		return false
	end

	local attr_id = field_def.id
	local field_type = field_def.type
	local insert_table = nil
	if field_type == _Byte then
		insert_table = input_table.byte_attr_list
	elseif field_type == _Bool then
		insert_table = input_table.bool_attr_list
	elseif field_type == _Int then
		insert_table = input_table.int_attr_list
	elseif field_type == _Float then
		insert_table = input_table.float_attr_list
	elseif field_type == _Short then
		insert_table = input_table.short_attr_list
	elseif field_type == _Int64 then
		insert_table = input_table.int64_attr_list
	elseif field_type == _String then
		insert_table = input_table.string_attr_list
	elseif field_type == _Struct then
		insert_table = input_table.struct_attr_list
	end

	if not insert_table then
		Log.warn("g_funcs.set_attr_table no insert table field_name=%s", field_name)
		return false
	end
	table.insert(insert_table, {attr_id=attr_id, value=value})

	return true
end

-- attr_table to attr_map
function g_funcs.attr_table_to_attr_map(table_def, attr_table, out_map)
	local attr_map = out_map or {}

	local function convert(input_attr_list)
		for _, v in ipairs(input_attr_list) do
			local field_def = table_def[v.attr_id]
			if not field_def then
				goto continue
			end
			attr_map[field_def.field] = v.value
			::continue::
		end
	end
	convert(attr_table.byte_attr_list)
	convert(attr_table.bool_attr_list)
	convert(attr_table.int_attr_list)
	convert(attr_table.float_attr_list)
	convert(attr_table.short_attr_list)
	convert(attr_table.int64_attr_list)
	convert(attr_table.string_attr_list)
	convert(attr_table.struct_attr_list)

	return attr_map
end

----------------

return g_funcs
