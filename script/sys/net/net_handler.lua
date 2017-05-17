
g_network = LuaNetwork:instance()

local function read_struct_array(structdef, deep)
	local ret = {}
	local count = g_network:read_int()
	for i = 1, count do
		local st = read_data_by_msgdef(structdef, deep)
		table.insert(ret, st)
	end
	return ret
end

local read_val_action = 
{
	[_Byte] = function() return g_network:read_byte() end,
	[_Bool] = function() return g_network:read_bool() end,
	[_Int] = function() return g_network:read_int() end,
	[_Float] = function() return g_network:read_float() end,
	[_Short] = function() return g_network:read_short() end,
	[_Int64] = function() return g_network:read_int64() end,
	[_String] = function() return g_network:read_string() end,

	[_ByteArray] = function() return g_network:read_byte_array() end,
	[_BoolArray] = function() return g_network:read_bool_array() end,
	[_IntArray] = function() return g_network:read_int_array() end,
	[_FloatArray] = function() return g_network:read_float_array() end,
	[_ShortArray] = function() return g_network:read_short_array() end,
	[_Int64Array] = function() return g_network:read_int64_array() end,
	[_StringArray] = function() return g_network:read_string_array() end,
}

local function read_data_by_msgdef(msgdef, deep)
	if deep > 10 then
		Log.warn("read_data_by_msgdef too deep")
	end

	local flag = true
	local ret = { }
	for idx, v in ipairs(msgdef) do
		local val_name = v[1]
		local val_type = v[2]

		if (val_type == _Struct) then
			flag, ret[val_name] = read_data_by_msgdef(v[3], deep + 1)
		elseif (val_type == _StructArray) then
			flag, ret[val_name] = read_struct_array(v[3], deep + 1)
		else
			flag, ret[val_name] = read_val_action[val_type]()
		end
		if not flag then
			Log.warn("read_data_by_msgdef read error")
			flag = false
			break
		end
	end
	return flag, ret
end

local function recv_msg(msg_id)
	local msgdef = MSG_DEF_MAP[msg_id]
	if not msgdef then
		Log.err("recv_msg msgdef not exists msg_id=%d", msg_id)
		return false
	end

	local flag, data = read_data_by_msgdef(msgdef, 0)
	return flag, data
end

local function recv_msg_handler(mailbox_id, msg_id)

	local flag, data = recv_msg(msg_id)	
	if not flag then
		Log.err("recv_msg_handler recv_msg fail mailbox_id=%d msg_id=%d", mailbox_id, msg_id)
		return
	end
	
	local msg_handler = Net.get_msg_handler(msg_id)
	if not msg_handler then
		Log.warn("recv_msg_handler handler not exists msg_id=%d", msg_id)
		return
	end

	msg_handler(data, mailbox_id, msg_id)
end

local function error_handler(msg, mailbox_id, msg_id)
	Log.err("error_handler=%s mailbox_id=%d msg_id=%d", msg, mailbox_id, msg_id)
end

function ccall_recv_msg_handler(mailbox_id, msg_id)
	Log.info("mailbox_id=", mailbox_id, " msg_id=", msg_id)
	local msg_name = MID._id_name_map[msg_id]
	Log.info("msg_name=", msg_name)
	
	local status = xpcall(recv_msg_handler
	, function(msg) return error_handler(msg, mailbox_id, msg_id) end
	, mailbox_id, msg_id)

end
