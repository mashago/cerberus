
NetMgr = class()

function NetMgr:ctor()
	local c_network = LuaNetwork:instance()
	self._c_network = c_network
	self._all_mailbox = {}

	self.read_value =
	{
		[_Byte] = function() return c_network:read_byte() end,
		[_Bool] = function() return c_network:read_bool() end,
		[_Int] = function() return c_network:read_int() end,
		[_Float] = function() return c_network:read_float() end,
		[_Short] = function() return c_network:read_short() end,
		[_Int64] = function() return c_network:read_int64() end,
		[_String] = function() return c_network:read_string() end,

		[_ByteArray] = function() return c_network:read_byte_array() end,
		[_BoolArray] = function() return c_network:read_bool_array() end,
		[_IntArray] = function() return c_network:read_int_array() end,
		[_FloatArray] = function() return c_network:read_float_array() end,
		[_ShortArray] = function() return c_network:read_short_array() end,
		[_Int64Array] = function() return c_network:read_int64_array() end,
		[_StringArray] = function() return c_network:read_string_array() end,
	}

	self.write_val_action = 
	{
		[_Byte] = function(val) return c_network:write_byte(val) end,
		[_Bool] = function(val) return c_network:write_bool(val) end,
		[_Int] = function(val) return c_network:write_int(val) end,
		[_Float] = function(val) return c_network:write_float(val) end,
		[_Short] = function(val) return c_network:write_short(val) end,
		[_Int64] = function(val) return c_network:write_int64(val) end,
		[_String] = function(val) return c_network:write_string(val) end,

		[_ByteArray] = function(val) return c_network:write_byte_array(val) end,
		[_BoolArray] = function(val) return c_network:write_bool_array(val) end,
		[_IntArray] = function(val) return c_network:write_int_array(val) end,
		[_FloatArray] = function(val) return c_network:write_float_array(val) end,
		[_ShortArray] = function(val) return c_network:write_short_array(val) end,
		[_Int64Array] = function(val) return c_network:write_int64_array(val) end,
		[_StringArray] = function(val) return c_network:write_string_array(val) end,
	}
end

function NetMgr:read_struct_array(structdef, deep)
	local ret = {}
	local flag, count = self._c_network:read_int()
	if not flag then
		Log.warn("NetMgr:read_struct_array count error")
		return flag, ret
	end

	for i = 1, count do
		local flag, st = self:read_data_by_msgdef(structdef, deep)
		if not flag then
			Log.warn("NetMgr:read_struct_array read data error")
			return flag, ret
		end
		table.insert(ret, st)
	end
	return flag, ret
end

local VALUE_NAME_INDEX = 1
local VALUE_TYPE_INDEX = 2
local VALUE_STRUCT_INDEX = 3

function NetMgr:read_data_by_msgdef(msgdef, deep)
	if deep > 10 then
		Log.warn("NetMgr:read_data_by_msgdef too deep")
	end

	local flag = true
	local ret = { }
	for idx, v in ipairs(msgdef) do
		local val_name = v[VALUE_NAME_INDEX]
		local val_type = v[VALUE_TYPE_INDEX]

		if (val_type == _Struct) then
			flag, ret[val_name] = self:read_data_by_msgdef(v[VALUE_STRUCT_INDEX], deep + 1)
		elseif (val_type == _StructArray) then
			flag, ret[val_name] = self:read_struct_array(v[VALUE_STRUCT_INDEX], deep + 1)
		elseif (val_type == _StructString) then
			flag, ret[val_name] = self.read_value[_String]()
			if flag then
				ret[val_name] = Util.unserialize(ret[val_name])
			end

		else
			flag, ret[val_name] = self.read_value[val_type]()
		end
		if not flag then
			Log.warn("NetMgr:read_data_by_msgdef read error val_type=%d", val_type)
			flag = false
			break
		end
	end
	return flag, ret
end

function NetMgr:unpack_msg(msg_id)
	local msgdef = MSG_DEF_MAP[msg_id]
	if not msgdef then
		Log.err("NetMgr:unpack_msg msgdef not exists msg_id=%d", msg_id)
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

function NetMgr:recv_msg_handler(mailbox_id, msg_id)
	local ext = self._c_network:read_ext()
	-- Log.debug("NetMgr:recv_msg_handler ext=%d", ext)
	
	-- check msg is local handle or transfer
	local msg_name = MID._id_name_map[msg_id]
	local msg_func = g_msg_handler[msg_name]
	if not msg_func then
		if not g_msg_handler.transfer_msg then
			Log.warn("NetMgr:recv_msg_handler handler not exists msg_name=%s", msg_name)
			return
		end
		return g_msg_handler.transfer_msg(mailbox_id, msg_id, ext)
	end

	local flag, data = self:unpack_msg(msg_id)
	if not flag then
		Log.err("NetMgr:recv_msg_handler unpack_msg fail mailbox_id=%d msg_name=%s", mailbox_id, msg_name)
		return
	end

	if is_trust_msg(msg_id) then
		local mailbox = self:get_mailbox(mailbox_id)
		if not mailbox then
			Log.warn("NetMgr:recv_msg_handler mailbox nil mailbox_id=%d msg_name=%s", mailbox_id, msg_name)
			return
		end

		if mailbox.conn_type ~= ConnType.TRUST then
			Log.warn("NetMgr:recv_msg_handler mailbox untrust mailbox_id=%d msg_name=%s", mailbox_id, msg_name)
			return
		end
	end

	if msg_id == MID.s2s_rpc_req then
		g_rpc_mgr:handle_call(data, mailbox_id, msg_id, false)
	elseif msg_id == MID.s2s_rpc_nocb_req then
		g_rpc_mgr:handle_call(data, mailbox_id, msg_id, true)
	elseif msg_id == MID.s2s_rpc_ret then
		g_rpc_mgr:handle_callback(data, mailbox_id, msg_id)
	elseif not RAW_MID[msg_id] and g_net_event_client_msg then
		-- check msg is need convert
		g_rpc_mgr:run(g_net_event_client_msg, msg_func, data, mailbox_id, msg_id, ext)
	else
		g_rpc_mgr:run(msg_func, data, mailbox_id, msg_id, ext)
	end

end

-------------- write

local function NetMgr:write_struct_array(data, structdef, deep)
	if not data then
		Log.err("NetMgr:write_struct_array data nil")
		return false
	end

	local ret = self._c_network:write_int(#data)
	if not ret then
		Log.err("NetMgr:write_struct_array write size error")
		return false
	end
	for k, v in ipairs(data) do
		ret = self:write_data_by_msgdef(v, structdef, deep)
		if not ret then
			Log.err("NetMgr:write_struct_array write struct error")
			return false
		end
	end
	return true
end

function NetMgr:write_data_by_msgdef(data, msgdef, deep)

	local flag = true
	for idx, v in ipairs(msgdef) do
		local val_name = v[1]
		local val_type = v[2]

		local value = data[val_name]
		if value == nil then
			Log.warn("NetMgr:write_data_by_msgdef value[%s] nil", val_name)
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
			Log.warn("NetMgr:write_data_by_msgdef value[%s] type error type(value)=%s val_type=%d", val_name, type(value), val_type)
			return false
		end

		if (val_type == _Struct) then
			flag = self:write_data_by_msgdef(value, v[3], deep+1)
		elseif (val_type == _StructArray) then
			flag = write_struct_array(value, v[3], deep+1)
		elseif (val_type == _StructString) then
			value = Util.serialize(value)
			flag = self.write_val_action[_String](value)
		else
			flag = self.write_val_action[val_type](value)
		end
		if not flag then
			Log.warn("NetMgr:write_data_by_msgdef write error val_type=%d", val_type)
			flag = false
			break
		end
	end
	return flag, ret
	
end



function NetMgr:send_msg_ext(mailbox_id, msg_id, ext, data)
	-- Log.debug("NetMgr:send_msg_ext msgdef mailbox_id=%d msg_id=%d ext=%d", mailbox_id, msg_id, ext)
	local msgdef = MSG_DEF_MAP[msg_id]
	if not msgdef then
		Log.err("NetMgr:send_msg_ext msgdef not exists msg_id=%d", msg_id)
		return false
	end

	local flag = self:write_data_by_msgdef(data, msgdef, 0)
	if not flag then
		Log.err("NetMgr:send_msg_ext write data error msg_id=%d", msg_id)
		self._c_network:clear_write()
		return false
	end

	self._c_network:write_msg_id(msg_id)
	self._c_network:write_ext(ext)
	return self._c_network:send(mailbox_id)
end

function NetMgr:send_msg(mailbox_id, msg_id, data)
	return NetMgr:send_msg_ext(mailbox_id, msg_id, 0, data)
end

-- transfer msg, copy data from recv pluto to send pluto, update ext if necessary
function NetMgr:transfer_msg(mailbox_id, ext)
	-- Log.debug("NetMgr:transfer_msg msgdef mailbox_id=%d ext=%d", mailbox_id, ext or 0)

	if ext then
		self._c_network:write_ext(ext)
	end
	return self._c_network:transfer(mailbox_id)
end

function NetMgr:add_mailbox(mailbox_id, ip, port)
	local conn_type = ConnType.UNTRUST
	if TrustIPList[ip] then
		conn_type = ConnType.TRUST
	end
	self._all_mailbox[mailbox_id] = 
	{
		mailbox_id = mailbox_id, 
		conn_type = conn_type,
		ip = ip,
		port = port,
	}
end

function NetMgr:get_mailbox(mailbox_id)
	return self._all_mailbox[mailbox_id]	
end

function NetMgr:del_mailbox(mailbox_id)
	self._all_mailbox[mailbox_id] = nil
end

function NetMgr:http_request_get(url, session_id)
	local post_data = ""
	local post_data_len = 0;
	self._c_network:http_request(url, session_id, HttpRequestType.GET, post_data, post_data_len)
end

function NetMgr:http_request_post(url, session_id, post_data, post_data_len)
	self._c_network:http_request(url, session_id, HttpRequestType.POST, post_data, post_data_len)
end

-------------------------------------------------------

-- for c call
function ccall_recv_msg_handler(mailbox_id, msg_id)
	Log.info("ccall_recv_msg_handler: mailbox_id=%d msg_id=%d", mailbox_id, msg_id)
	local msg_name = MID._id_name_map[msg_id] or "unknow msg"
	Log.info("msg_name=%s", msg_name)

	local function error_handler(msg, mailbox_id, msg_id)
		Log.err("error_handler=%s mailbox_id=%d msg_id=%d", msg, mailbox_id, msg_id)
	end
	
	local status = xpcall(g_net_mgr.recv_msg_handler
	, function(msg) return error_handler(msg, mailbox_id, msg_id) end
	, g_net_mgr, mailbox_id, msg_id)

end

function ccall_disconnect_handler(mailbox_id)
	Log.warn("ccall_disconnect_handler mailbox_id=%d", mailbox_id)

	local function error_handler(msg, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_disconnect_handler error : mailbox_id = %d \n%s", mailbox_id, msg)
		return msg 
	end

	local function handle_disconnect(mailbox_id)
		
		local server_info = g_service_mgr:get_server_by_mailbox(mailbox_id)
		if server_info then
			-- service disconnect
			Log.warn("ccall_disconnect_handler service_client disconnect %d", mailbox_id)
			if g_net_event_server_disconnect and server_info._connect_status == ServiceConnectStatus.CONNECTED then
				g_net_event_server_disconnect(server_info._server_id)
			end
			g_service_mgr:handle_disconnect(mailbox_id)
		else
			-- client disconnect, login and gate handle
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
	Log.info("ccall_connect_to_ret_handler connect_index=%d mailbox_id=%d", connect_index, mailbox_id)

	local function error_handler(msg, connect_index, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_connect_to_ret_handler error : connect_index = %d mailbox_id = %d \n%s", connect_index, mailbox_id, msg)
		return msg 
	end
	
	local status, msg = xpcall(g_service_mgr.connect_to_ret
	, function(msg) return error_handler(msg, connect_index, mailbox_id) end
	, g_service_mgr, connect_index, mailbox_id)

	if not status then
		Log.err(msg)
	end
end

function ccall_connect_to_success_handler(mailbox_id)
	Log.info("ccall_connect_to_success_handler mailbox_id=%d", mailbox_id)

	local function error_handler(msg, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_connect_to_success_handler error : mailbox_id = %d \n%s", mailbox_id, msg)
		return msg 
	end
	
	local status, msg = xpcall(g_service_mgr.connect_to_success
	, function(msg) return error_handler(msg, mailbox_id) end
	, g_service_mgr, mailbox_id)

	if not status then
		Log.err(msg)
	end
end

function ccall_new_connection(mailbox_id, ip, port)
	Log.info("ccall_new_connection mailbox_id=%d ip=%s, port=%d", mailbox_id, ip, port)

	local function error_handler(msg, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_new_connection error : mailbox_id = %d \n%s", mailbox_id, msg)
		return msg 
	end
	
	local status, msg = xpcall(g_net_mgr.add_mailbox
	, function(msg) return error_handler(msg, mailbox_id) end
	, g_net_mgr, mailbox_id, ip, port)

	if not status then
		Log.err(msg)
	end
end

function ccall_http_response_handler(session_id, response_code, content)

	local function error_handler(msg, session_id, response_code)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_http_response_handler error : session_id = %d response_code = %d \n%s", session_id, response_code, msg)
		return msg 
	end
	
	local status, msg = xpcall(g_http_mgr.handle_request
	, function(msg) return error_handler(msg, session_id, response_code) end
	, g_http_mgr, session_id, response_code, content)

	if not status then
		Log.err(msg)
	end
end

return NetMgr
