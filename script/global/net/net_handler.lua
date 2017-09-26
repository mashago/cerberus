
g_network = LuaNetwork:instance(g_luaworld_ptr)

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

local function read_struct_array(structdef, deep)
	local ret = {}
	local flag, count = g_network:read_int()
	if not flag then
		Log.warn("read_struct_array count error")
		return flag, ret
	end

	for i = 1, count do
		local flag, st = read_data_by_msgdef(structdef, deep)
		if not flag then
			Log.warn("read_struct_array read data error")
			return flag, ret
		end
		table.insert(ret, st)
	end
	return flag, ret
end

function read_data_by_msgdef(msgdef, deep)
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
		elseif (val_type == _StructString) then
			flag, ret[val_name] = read_val_action[_String]()
			if flag then
				ret[val_name] = Util.unserialize(ret[val_name])
			end

		else
			flag, ret[val_name] = read_val_action[val_type]()
		end
		if not flag then
			Log.warn("read_data_by_msgdef read error val_type=%d", val_type)
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

local function is_trust_msg(msg_id)
	--[[
	if TRUST_MID[msg_id] then
		return true
	end
	--]]
	if msg_id >= 60001 then
		return true
	end
	return false
end

local function recv_msg_handler(mailbox_id, msg_id)
	local ext = g_network:read_ext()
	-- Log.debug("recv_msg_handler ext=%d", ext)
	
	local msg_handler = Net.get_msg_handler(msg_id)
	if not msg_handler then
		if g_net_event_transfer_msg then
			g_net_event_transfer_msg(mailbox_id, msg_id, ext)
		else
			Log.warn("recv_msg_handler handler not exists msg_id=%d", msg_id)
		end
		return
	end

	local flag, data = recv_msg(msg_id)	
	if not flag then
		Log.err("recv_msg_handler recv_msg fail mailbox_id=%d msg_id=%d", mailbox_id, msg_id)
		return
	end

	if is_trust_msg(msg_id) then
		local mailbox = Net.get_mailbox(mailbox_id)
		if not mailbox then
			Log.warn("recv_msg_handler mailbox nil mailbox_id=%d msg_id=%d", mailbox_id, msg_id)
			return
		end

		if mailbox.conn_type ~= ConnType.TRUST then
			Log.warn("recv_msg_handler mailbox untrust mailbox_id=%d msg_id=%d", mailbox_id, msg_id)
			return
		end
	end

	if not RAW_MID[msg_id] and g_net_event_client_msg then
		-- g_net_event_client_msg(msg_handler, data, mailbox_id, msg_id, ext)
		RpcMgr.run(g_net_event_client_msg, msg_handler, data, mailbox_id, msg_id, ext)
	else
		-- msg_handler(data, mailbox_id, msg_id, ext)

		if msg_id == MID.REMOTE_CALL_REQ then
			RpcMgr.handle_call(data, mailbox_id, msg_id)
		elseif msg_id == MID.REMOTE_CALL_RET then
			RpcMgr.handle_callback(data, mailbox_id, msg_id)
		else
			RpcMgr.run(msg_handler, data, mailbox_id, msg_id, ext)
		end
	end
end

-------------- write

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

function write_data_by_msgdef(data, msgdef, deep)

	local flag = true
	for idx, v in ipairs(msgdef) do
		local val_name = v[1]
		local val_type = v[2]

		local value = data[val_name]
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
			and val_type ~= _Struct and val_type ~= _StructArray and val_type ~= _StructString))
		then
			Log.warn("write_data_by_msgdef value[%s] type error type(value)=%s val_type=%d", val_name, type(value), val_type)
			return false
		end

		if (val_type == _Struct) then
			flag = write_data_by_msgdef(value, v[3], deep+1)
		elseif (val_type == _StructArray) then
			flag = write_struct_array(value, v[3], deep+1)
		elseif (val_type == _StructString) then
			value = Util.serialize(value)
			flag = write_val_action[_String](value)
		else
			flag = write_val_action[val_type](value)
		end
		if not flag then
			Log.warn("write_data_by_msgdef write error val_type=%d", val_type)
			flag = false
			break
		end
	end
	return flag, ret
	
end


function ccall_recv_msg_handler(mailbox_id, msg_id)
	mailbox_id = math.floor(mailbox_id)
	Log.info("ccall_recv_msg_handler: mailbox_id=%d msg_id=%d", mailbox_id, msg_id)
	local msg_name = MID._id_name_map[msg_id] or "unknow msg"
	Log.info("msg_name=%s", msg_name)

	local function error_handler(msg, mailbox_id, msg_id)
		Log.err("error_handler=%s mailbox_id=%d msg_id=%d", msg, mailbox_id, msg_id)
	end
	
	local status = xpcall(recv_msg_handler
	, function(msg) return error_handler(msg, mailbox_id, msg_id) end
	, mailbox_id, msg_id)

end

function ccall_disconnect_handler(mailbox_id)
	mailbox_id = math.floor(mailbox_id)
	Log.warn("ccall_disconnect_handler mailbox_id=%d", mailbox_id)

	local function error_handler(msg, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_disconnect_handler error : mailbox_id = %d \n%s", mailbox_id, msg)
		return msg 
	end

	local function handle_disconnect(mailbox_id)
		
		if ServiceServer.is_service_client(mailbox_id) then
			Log.warn("ccall_disconnect_handler service_client disconnect %d", mailbox_id)
			-- service client disconnect
			local server_info = ServiceServer.get_server_by_mailbox(mailbox_id)
			if g_net_event_server_disconnect then
				g_net_event_server_disconnect(server_info._server_id)
			end
			ServiceServer.handle_disconnect(mailbox_id)
		elseif ServiceClient.is_service_server(mailbox_id) then
			-- service server disconnect
			Log.warn("ccall_disconnect_handler service_server disconnect %d", mailbox_id)
			ServiceClient.handle_disconnect(mailbox_id)
		else
			-- client disconnect
			Log.warn("ccall_disconnect_handler client disconnect %d", mailbox_id)
			if g_net_event_client_disconnect then
				g_net_event_client_disconnect(mailbox_id)
			end
		end

		Net.del_mailbox(mailbox_id)
	end
	
	local status, msg = xpcall(handle_disconnect
	, function(msg) return error_handler(msg, mailbox_id) end
	, mailbox_id)

	if not status then
		Log.err(msg)
	end
end

function ccall_connect_to_ret_handler(connect_index, mailbox_id)
	connect_index = math.floor(connect_index)
	mailbox_id = math.floor(mailbox_id)
	Log.info("ccall_connect_to_ret_handler connect_index=%d mailbox_id=%d", connect_index, mailbox_id)

	local function error_handler(msg, connect_index, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_connect_to_ret_handler error : connect_index = %d mailbox_id = %d \n%s", connect_index, mailbox_id, msg)
		return msg 
	end
	
	local status, msg = xpcall(ServiceClient.connect_to_ret
	, function(msg) return error_handler(msg, connect_index, mailbox_id) end
	, connect_index, mailbox_id)

	if not status then
		Log.err(msg)
	end
end

function ccall_connect_to_success_handler(mailbox_id)
	mailbox_id = math.floor(mailbox_id)
	Log.info("ccall_connect_to_success_handler mailbox_id=%d", mailbox_id)

	local function error_handler(msg, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_connect_to_success_handler error : mailbox_id = %d \n%s", mailbox_id, msg)
		return msg 
	end
	
	local status, msg = xpcall(ServiceClient.connect_to_success
	, function(msg) return error_handler(msg, mailbox_id) end
	, mailbox_id)

	if not status then
		Log.err(msg)
	end
end

function ccall_new_connection(mailbox_id, conn_type)
	mailbox_id = math.floor(mailbox_id)
	Log.info("ccall_new_connection mailbox_id=%d conn_type=%d", mailbox_id, conn_type)

	local function error_handler(msg, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_new_connection error : mailbox_id = %d \n%s", mailbox_id, msg)
		return msg 
	end
	
	local status, msg = xpcall(Net.add_mailbox
	, function(msg) return error_handler(msg, mailbox_id) end
	, mailbox_id, conn_type)

	if not status then
		Log.err(msg)
	end
end

function ccall_http_response_handler(session_id, response_code, content)
	session_id = math.floor(session_id)
	-- Log.info("ccall_http_response_handler session_id=%d response_code=%d", session_id, response_code)
	Log.info("ccall_http_response_handler session_id=%d response_code=%d content=%s", session_id, response_code, content)

	local function error_handler(msg, session_id, response_code)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_http_response_handler error : session_id = %d response_code = %d \n%s", session_id, response_code, msg)
		return msg 
	end
	
	--[[
	local status, msg = xpcall(handle_func
	, function(msg) return error_handler(msg, session_id, response_code) end
	, session_id, response_code, content)

	if not status then
		Log.err(msg)
	end
	--]]
end

