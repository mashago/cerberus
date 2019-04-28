
local server_mgr = require "server.server_mgr"
local Log = require "log.logger"
local Util = require "util.util"
local cutil = require "cerberus.util"
local msg_def = require "global.net_msg_def"
local ErrorCode = require "global.error_code"
local MID = msg_def.MID

local g_funcs = {}
function g_funcs.debug_timer_cb()
	-- Log.debug("********* g_funcs.debug_timer_cb")
	-- local rpc_mgr = require "rpc.rpc_mgr"
	-- rpc_mgr:print()
	-- local count = collectgarbage("count")
	-- Log.debug("mem count=%f", count)
end

-- about shake hand
-- a common handle for MID.s2s_shake_hand_req
-- master server NOT use this function
function g_funcs.handle_shake_hand_req(data, mailbox_id)
	Log.debug("g_funcs.handle_shake_hand_req data=%s", Util.table_to_string(data))

	local server_id = data.server_id
	local server_type = data.server_type
	local single_scene_list = data.single_scene_list
	local from_to_scene_list = data.from_to_scene_list
	-- local ip = data.ip -- will ignore
	-- local port = data.port -- will ignore

	local server_conf = require "global.server_conf"
	local msg = 
	{
		result = ErrorCode.SUCCESS,
		server_id = server_conf._server_id,
		server_type = server_conf._server_type,
		single_scene_list = server_conf._single_scene_list,
		from_to_scene_list = server_conf._from_to_scene_list,
	}

	-- add server
	local server_info = server_mgr:add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)
	if not server_info then
		Log.warning("g_funcs.handle_shake_hand_req add_server fail server_id=%d server_type=%d", server_id, server_type)
		msg.result = ErrorCode.SHAKE_HAND_FAIL
		local net_mgr = require "net.net_mgr"
		net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_ret, msg)
		return
	end

	server_info:send_msg(MID.s2s_shake_hand_ret, msg)

	if g_net_event_server_connect then
		g_net_event_server_connect(server_id)
	end
end

-- a common handle for MID.s2s_shake_hand_ret
function g_funcs.handle_shake_hand_ret(data, mailbox_id)
	Log.debug("g_funcs.handle_shake_hand_ret data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.err("handle_shake_hand_ret: fail %d", data.result)
		return
	end
	local server_id = data.server_id
	local server_type = data.server_type
	local single_scene_list = data.single_scene_list
	local from_to_scene_list = data.from_to_scene_list

	local ret = server_mgr:shake_hand_success(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	if not ret then
		return
	end

	if g_net_event_server_connect then
		g_net_event_server_connect(server_id)
	end
end

-- a common handle for MID.s2s_shake_hand_invite
function g_funcs.handle_shake_hand_invite(data, mailbox_id)
	Log.debug("g_funcs.handle_shake_hand_invite data=%s", Util.table_to_string(data))
	for k, v in ipairs(data.peer_list) do
		local ip = v.ip
		local port = v.port
		local server_id = 0
		local server_type = 0
		local no_shakehand = false
		local no_reconnect = false
		
		local server_info = server_mgr:get_server_by_host(ip, port)
		if server_info then
			server_info:set_no_reconnect(no_reconnect)
		else
			server_mgr:do_connect(ip, port, server_id, server_type, no_shakehand, no_reconnect)
		end
	end
end
--

-- a common handle for MID.s2s_shake_hand_cancel
-- master detect one peer disconnect
-- that server connection may close later or may invite again
-- so mark mark server no_reconnect, 
function g_funcs.handle_shake_hand_cancel(data, mailbox_id)
	Log.debug("g_funcs.handle_shake_hand_cancel data=%s", Util.table_to_string(data))

	-- local server_id = data.server_id
	local ip = data.ip
	local port = data.port

	local server_info = server_mgr:get_server_by_host(ip, port)
	if not server_info then
		return
	end

	server_info:set_no_reconnect(true)
end
--

-------- for attr data and string convert

function g_funcs.register_attr_func(obj_class, obj_def)
	for _, line in ipairs(obj_def) do
		local field_name = line.field
		obj_class["set_" .. field_name] = function(self, value)
			self:modify_attr(field_name, value)
		end

	end
end

function g_funcs.register_getter_setter(class, sheet_name)
	local table_def = DataStructDef.data[sheet_name]
	for _, field_def in ipairs(table_def) do
		local field_name = field_def.field
		class["set_" .. field_name] = function(self, value, ...)
			self:modify(field_name, value, ...)
		end

		class["get_" .. field_name] = function(self, ...)
			return self:get_attr(field_name, ...)
		end

	end
end

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
	convert(attr_table.byte_attr_list or {})
	convert(attr_table.bool_attr_list or {})
	convert(attr_table.int_attr_list or {})
	convert(attr_table.float_attr_list or {})
	convert(attr_table.short_attr_list or {})
	convert(attr_table.int64_attr_list or {})
	convert(attr_table.string_attr_list or {})
	convert(attr_table.struct_attr_list or {})

	return attr_map
end

function g_funcs.get_msg_name(msg_id)
	return MID._id_name_map[msg_id] or "NIL_MSG"
end

function g_funcs.gen_random_name()
	math.randomseed(cutil.get_time_ms())
	local ascii_table = {}
	for i=48, 57 do
		table.insert(ascii_table, i)
	end
	for i=97, 122 do
		table.insert(ascii_table, i)
	end

	local name = ""
	local name_len = 10
	for i=1, name_len do
		local r = math.random(1, #ascii_table)
		local n = ascii_table[r]
		local c = string.char(n)
		name = name .. c
	end

	return name
end

----------------

return g_funcs
