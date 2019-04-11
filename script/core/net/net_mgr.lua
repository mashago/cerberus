
local Log = require "log.logger"
local Util = require "util.util"
local cnetwork = require "cerberus.network"

local NetMgr = {
	_all_mailbox = {},

	_read_val_funcs =
	{
		[_Byte] = function() return cnetwork.read_byte() end,
		[_Bool] = function() return cnetwork.read_bool() end,
		[_Int] = function() return cnetwork.read_int() end,
		[_Float] = function() return cnetwork.read_float() end,
		[_Short] = function() return cnetwork.read_short() end,
		[_Int64] = function() return cnetwork.read_int64() end,
		[_String] = function() return cnetwork.read_string() end,

		[_ByteArray] = function() return cnetwork.read_byte_array() end,
		[_BoolArray] = function() return cnetwork.read_bool_array() end,
		[_IntArray] = function() return cnetwork.read_int_array() end,
		[_FloatArray] = function() return cnetwork.read_float_array() end,
		[_ShortArray] = function() return cnetwork.read_short_array() end,
		[_Int64Array] = function() return cnetwork.read_int64_array() end,
		[_StringArray] = function() return cnetwork.read_string_array() end,
	},

	_write_val_funcs =
	{
		[_Byte] = function(val) return cnetwork.write_byte(val) end,
		[_Bool] = function(val) return cnetwork.write_bool(val) end,
		[_Int] = function(val) return cnetwork.write_int(val) end,
		[_Float] = function(val) return cnetwork.write_float(val) end,
		[_Short] = function(val) return cnetwork.write_short(val) end,
		[_Int64] = function(val) return cnetwork.write_int64(val) end,
		[_String] = function(val) return cnetwork.write_string(val) end,

		[_ByteArray] = function(val) return cnetwork.write_byte_array(val) end,
		[_BoolArray] = function(val) return cnetwork.write_bool_array(val) end,
		[_IntArray] = function(val) return cnetwork.write_int_array(val) end,
		[_FloatArray] = function(val) return cnetwork.write_float_array(val) end,
		[_ShortArray] = function(val) return cnetwork.write_short_array(val) end,
		[_Int64Array] = function(val) return cnetwork.write_int64_array(val) end,
		[_StringArray] = function(val) return cnetwork.write_string_array(val) end,
	},
}

local VALUE_NAME_INDEX = 1
local VALUE_TYPE_INDEX = 2
local VALUE_STRUCT_INDEX = 3


function NetMgr:read_data_by_msgdef(msgdef, deep)
	if deep > 10 then
		Log.warn("NetMgr:read_data_by_msgdef too deep %d", deep)
	end

	local read_val_funcs = self._read_val_funcs

	local flag = true
	local ret = { }
	for k, v in ipairs(msgdef) do
		local val_name = v[VALUE_NAME_INDEX]
		local val_type = v[VALUE_TYPE_INDEX]

		if (val_type == _Struct) then
			flag, ret[val_name] = self:read_data_by_msgdef(v[VALUE_STRUCT_INDEX], deep + 1)
		elseif (val_type == _StructArray) then
			flag, ret[val_name] = self:read_struct_array(v[VALUE_STRUCT_INDEX], deep + 1)
		elseif (val_type == _StructString) then
			flag, ret[val_name] = read_val_funcs[_String]()
			if flag then
				ret[val_name] = Util.unserialize(ret[val_name])
			end
		else
			flag, ret[val_name] = read_val_funcs[val_type]()
		end
		if not flag then
			Log.warn("NetMgr:read_data_by_msgdef read error k=%d val_type=%d", k, val_type)
			flag = false
			break
		end
	end
	return flag, ret
end

function NetMgr:read_struct_array(structdef, deep)
	local ret = {}

	local flag, size = self._read_val_funcs[_Int]()
	if not flag then
		Log.warn("NetMgr:read_struct_array read size error")
		return flag, ret
	end

	for i = 1, size do
		local st
		flag, st = self:read_data_by_msgdef(structdef, deep)
		if not flag then
			Log.warn("NetMgr:read_struct_array read data error")
			return flag, ret
		end
		table.insert(ret, st)
	end
	return flag, ret
end

function NetMgr:unpack_msg(msg_id)
	local msgdef = MSG_DEF_MAP[msg_id]
	if not msgdef then
		Log.err("NetMgr:unpack_msg msgdef not exists msg_id=%d", msg_id)
		return false
	end

	local flag, data = self:read_data_by_msgdef(msgdef, 0)
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
	local ext = cnetwork.read_ext()
	-- Log.debug("NetMgr:recv_msg_handler ext=%d", ext)
	
	-- check msg is local handle or transfer
	local msg_name = MID._id_name_map[msg_id]
	local g_msg_handler = require "global.msg_handler"
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

	local rpc_mgr = require "rpc.rpc_mgr"
	if msg_id == MID.s2s_rpc_req then
		rpc_mgr:handle_call(data, mailbox_id, msg_id, false)
	elseif msg_id == MID.s2s_rpc_send_req then
		rpc_mgr:handle_call(data, mailbox_id, msg_id, true)
	elseif msg_id == MID.s2s_rpc_ret then
		rpc_mgr:handle_callback(data, mailbox_id, msg_id)
	elseif not RAW_MID[msg_id] and g_net_event_client_msg then
		-- check msg is need convert
		rpc_mgr:run(g_net_event_client_msg, msg_func, data, mailbox_id, msg_id, ext)
	else
		rpc_mgr:run(msg_func, data, mailbox_id, msg_id, ext)
	end

end

-------------- write

function NetMgr:write_data_by_msgdef(data, msgdef, deep)
	
	local write_val_funcs = self._write_val_funcs

	local flag = true
	for k, v in ipairs(msgdef) do
		local val_name = v[VALUE_NAME_INDEX]
		local val_type = v[VALUE_TYPE_INDEX]

		local value = data[val_name]
		if not value then
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
			and val_type ~= _Struct and val_type ~= _StructArray 
			and val_type ~= _StructString))
		then
			Log.warn("NetMgr:write_data_by_msgdef value[%s] type error type(value)=%s val_type=%d", val_name, type(value), val_type)
			return false
		end

		if (val_type == _Struct) then
			flag = self:write_data_by_msgdef(value, v[VALUE_STRUCT_INDEX], deep+1)
		elseif (val_type == _StructArray) then
			flag = self:write_struct_array(value, v[VALUE_STRUCT_INDEX], deep+1)
		elseif (val_type == _StructString) then
			value = Util.serialize(value)
			flag = write_val_funcs[_String](value)
		else
			flag = write_val_funcs[val_type](value)
		end
		if not flag then
			Log.warn("NetMgr:write_data_by_msgdef write error k=%d val_type=%d", k, val_type)
			flag = false
			break
		end
	end
	return flag
	
end

function NetMgr:write_struct_array(data, structdef, deep)
	if not data then
		Log.err("NetMgr:write_struct_array data nil")
		return false
	end

	local ret = self._write_val_funcs[_Int](#data)
	if not ret then
		Log.err("NetMgr:write_struct_array write size error")
		return false
	end
	for k, v in ipairs(data) do
		ret = self:write_data_by_msgdef(v, structdef, deep)
		if not ret then
			Log.err("NetMgr:write_struct_array write data error")
			return false
		end
	end
	return true
end

------------------------------------

function NetMgr:send_msg_ext(mailbox_id, msg_id, ext, data)
	-- Log.debug("NetMgr:send_msg_ext msgdef mailbox_id=%d msg_id=%d ext=%d", mailbox_id, msg_id, ext)
	if mailbox_id == MAILBOX_ID_NIL then
		return false
	end

	local msgdef = MSG_DEF_MAP[msg_id]
	if not msgdef then
		Log.err("NetMgr:send_msg_ext msgdef not exists msg_id=%d", msg_id)
		return false
	end

	local flag = self:write_data_by_msgdef(data, msgdef, 0)
	if not flag then
		Log.err("NetMgr:send_msg_ext write data error msg_id=%d", msg_id)
		cnetwork.clear_write()
		return false
	end

	cnetwork.write_msg_id(msg_id)
	cnetwork.write_ext(ext)
	return cnetwork.send(mailbox_id)
end

function NetMgr:send_msg(mailbox_id, msg_id, data)
	return self:send_msg_ext(mailbox_id, msg_id, 0, data)
end

-- transfer msg, copy data from recv pluto to send pluto, update ext if necessary
function NetMgr:transfer_msg(mailbox_id, ext)
	-- Log.debug("NetMgr:transfer_msg msgdef mailbox_id=%d ext=%d", mailbox_id, ext or 0)

	cnetwork.write_ext(ext or 0)
	return cnetwork.transfer(mailbox_id)
end

function NetMgr:close_mailbox(mailbox_id)
	return cnetwork.close_mailbox(mailbox_id)
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
	cnetwork.http_request(url, session_id, HttpRequestType.GET, post_data, post_data_len)
end

function NetMgr:http_request_post(url, session_id, post_data, post_data_len)
	cnetwork.http_request(url, session_id, HttpRequestType.POST, post_data, post_data_len)
end

return NetMgr
