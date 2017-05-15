
g_network = LuaNetwork:instance()

local function read_struct_array(structdef, deep)
	local ret = {}
	local count = g_network:read_int()
	for i = 1, count do
		local st = read_data_by_def(structdef, deep)
		table.insert(ret, st)
	end
	return ret
end

local function read_data_by_def(msgdef, deep)
	if deep > 10 then
		print("too deep")
	end

	local read_val_action = 
	{
		[_Byte] = function() return g_network:read_byte() end,
		[_Bool] = function() return g_network:read_bool() end,
		[_Int] = function() return g_network:read_int() end,
		[_Float] = function() return g_network:read_float() end,
		[_Short] = function() return g_network:read_short() end,
		[_LongLong] = function() return g_network:read_longlong() end,
		[_String] = function() return g_network:read_string() end,

		[_ByteArray] = function() return g_network:read_byte_array() end,
		[_BoolArray] = function() return g_network:read_bool_array() end,
		[_IntArray] = function() return g_network:read_int_array() end,
		[_FloatArray] = function() return g_network:read_float_array() end,
		[_ShortArray] = function() return g_network:read_short_array() end,
		[_LongLongArray] = function() return g_network:read_longlong_array() end,
		[_StringArray] = function() return g_network:read_string_array() end,
    }

	local flag = true
	local ret = { }
	for idx, v in ipairs(msgdef) do
		local val_name = v[1]
		local val_type = v[2]

		print("val_name=", val_name, " val_type=", val_type)
		if (val_type == _Struct) then
			flag, ret[val_name] = read_data_by_msg_def(v[3], deep + 1)
		elseif (val_type == _StructArray) then
			flag, ret[val_name] = read_struct_array(v[3], deep + 1)
		else
			flag, ret[val_name] = read_val_action[val_type]()
		end
		if not flag then
			print("read_data_by_def read error")
			break
		end
	end
	return true, ret
end

local function recv_msg(msg_id)
	local def = MSG_DEF_MAP[msg_id]
	if not def then
		print("recv_msg(msg_id) def not exists")
		return
	end

	local flag, data = read_data_by_def(def, 0)
	return flag, data
end


local function recv_msg_handler(mailbox_id, msg_id)
	local flag, data = recv_msg(msg_id)	
	
	if msg_id == MID.CLIENT_TEST then
		print("data.client_time=", data.client_time, " data.client_data=", data.client_data)
	end
end

local function error_handler(msg, mailbox_id, msg_id)
	print("error_handler ", msg)
end

function ccall_net_recv_msg_handler(mailbox_id, msg_id)
	print("mailbox_id=", mailbox_id, " msg_id=", msg_id)
	local msg_name = MID._id_name_map[msg_id]
	print("msg_name=", msg_name)
	
	local status = xpcall(recv_msg_handler
	, function(msg) return error_handler(msg, mailbox_id, msg_id) end
	, mailbox_id, msg_id)

end
