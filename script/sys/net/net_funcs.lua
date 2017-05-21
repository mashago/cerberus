
Net = {}
Net._msg_handler_map = {}

local write_val_action = 
{
	[_Byte] = function(val) return g_network:write_byte(val) end,
	[_Bool] = function(val) return g_network:write_bool(val) end,
	[_Int] = function(val) return g_network:write_int(val) end,
	[_Float] = function(val) return g_network:write_float(val) end,
	[_Short] = function(val) return g_network:write_short(val) end,
	[_Int64] = function(val) return g_network:write_int64(val) end,
	[_String] = function(val) return g_network:write_string(val) end,

	[_ByteArray] = function(val) return g_network:write_byte_array(val) end,
	[_BoolArray] = function(val) return g_network:write_bool_array(val) end,
	[_IntArray] = function(val) return g_network:write_int_array(val) end,
	[_FloatArray] = function(val) return g_network:write_float_array(val) end,
	[_ShortArray] = function(val) return g_network:write_short_array(val) end,
	[_Int64Array] = function(val) return g_network:write_int64_array(val) end,
	[_StringArray] = function(val) return g_network:write_string_array(val) end,
}

local function write_struct_array(data, structdef, deep)
	if not data then
		Log.err("write_struct_array data nil")
		return false
	end

	local ret = g_network:write_int(#data)
	if not ret then
		Log.err("write_struct_array write size error")
		return false
	end
	for k, v in ipairs(data) do
		ret = write_data_by_msgdef(v, structdef, deep)
		if not ret then
			Log.err("write_struct_array write struct error")
			return false
		end
	end
	return true
end

local function write_data_by_msgdef(data, msgdef, deep)

	for idx, v in ipairs(msgdef) do
		local val_name = v[1]
		local val_type = v[2]

		local value = data[idx]
		if value == nil then
			Log.warn("write_data_by_msgdef value[%s] nil", val_name)
			return false
		end

		if (type(value) == "string" and val_type ~= _String)
		or (type(value) == "boolean" and val_type ~= _Bool)
		or (type(value) == "number" and (val_type ~= _Byte
			and val_type ~= _Short and val_type ~= _Int
			and val_type ~= _Float and val_type ~= _Int64))
		or (type(value) == "table" and (val_type ~= _ByteArray
			and val_type ~= _ShortArray and val_type ~= _IntArray
			and val_type ~= _FloatArray and val_type ~= _Int64Array
			and val_type ~= _BoolArray and val_type ~= _StringArray
			and val_type ~= _Struct and val_type ~= _StructArray))
		then
			Log.warn("write_data_by_msgdef value[%s] type error type(value)=%s val_type=%d", val_name, type(value), val_type)
			return false
		end

		if (val_type == _Struct) then
			flag = write_data_by_msgdef(value, v[3], deep+1)
		elseif (val_type == _StructArray) then
			flag = write_struct_array(value, v[3], deep+1)
		else
			flag = write_val_action[val_type](value)
		end
		if not flag then
			Log.warn("write_data_by_msgdef write error")
			flag = false
			break
		end
	end
	return flag, ret
	
end

function Net.send_msg(mailbox_id, msg_id, ...)
	local msgdef = MSG_DEF_MAP[msg_id]
	if not msgdef then
		Log.err("Net.send_msg msgdef not exists msg_id=%d", msg_id)
		return false
	end

	local args = {...}
	if #msgdef ~= #args then
		Log.err("Net.send_msg args count error msg_id=%d", msg_id)
		return false
	end

	local flag = write_data_by_msgdef(args, msgdef, 0)
	if not flag then
		Log.err("Net.send_msg write data error msg_id=%d", msg_id)
		return false
	end

	g_network:write_msg_id(msg_id)
	return g_network:send(mailbox_id)
end

function Net.add_msg_handler(msg_id, func)
	local f = Net._msg_handler_map[msg_id]
	if f then
		print("Net.add_msg_handler duplicate ", msg_id)
	end
	Net._msg_handler_map[msg_id] = func
end

function Net.get_msg_handler(msg_id)
	return Net._msg_handler_map[msg_id]
end

