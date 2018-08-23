
local Env = require "env"
local Log = require "core.log.logger"
local Util = require "core.util.util"
local class = require "core.util.class"
local g_funcs = require "core.global.global_funcs"
local ErrorCode = ErrorCode
local ServerType = ServerType

local CommonMgr = class()

function CommonMgr:ctor()
	-- {[server_id] = conn_num, }
	self._gate_conn_map = {}

	-- {
	-- 		[user_id] = 
	-- 		{
	-- 			role_id = x,
	-- 			token = z,
	-- 			gate_server_id = n,
	-- 		},
	-- }
	self._online_user_map = {}

end

function CommonMgr:sync_gate_conn_num(gate_server_id, num)
	self._gate_conn_map[gate_server_id] = num
end

-- return table for rpc call
function CommonMgr:rpc_create_role(custom_data)

	-- rpc to db to insert role_info
	local role_data = {}

	-- set default value by config
	for _, field_def in ipairs(DataStructDef.data.role_info) do
		local field_name = field_def.field
		if not field_def.save or field_def.save == 0 or field_def.default == '_Null' then
			goto continue
		end
		local default = g_funcs.str_to_value(field_def.default, field_def.type)
		role_data[field_name]=default
		::continue::
	end
	Log.debug("CommonMgr:rpc_create_role role_data=%s", Util.table_to_string(role_data))

	-- set custom value
	for k, v in pairs(custom_data) do
		role_data[k] = v
	end

	-- just do a insert
	local rpc_data =
	{
		table_name = "role_info",
		kvs = role_data,
	}
	local status, ret = Env.rpc_mgr:call_by_server_type(ServerType.DB, "db_game_insert", rpc_data)
	if not status then
		Log.err("CommonMgr:rpc_create_role rpc call fail")
		return {result = ErrorCode.SYS_ERROR}
	end
	Log.debug("CommonMgr:rpc_create_role callback ret=%s", Util.table_to_string(ret))

	return {result = ret.result}
end

-- return table for rpc call
function CommonMgr:rpc_delete_role(user_id, role_id)

	-- check if already enter
	local online_user = self._online_user_map[user_id]
	if online_user and online_user.role_id == role_id then
		-- rpc to gate, kick role
		local rpc_data = 
		{
			user_id = user_id,
			role_id = role_id,
			reason = ErrorCode.ROLE_KICK_RELOGIN,
		}
		local status, ret = Env.rpc_mgr:call_by_server_id(online_user.gate_server_id, "gate_kick_role", rpc_data)
		if not status then
			Log.err("rpc_delete_role rpc call fail")
			return {result = ErrorCode.SYS_ERROR}
		end
		Log.debug("rpc_delete_role: callback ret=%s", Util.table_to_string(ret))
		if ret.result ~= ErrorCode.SUCCESS then
			return {result = ret.result}
		end
		self._online_user_map[user_id] = nil
	end

	-- core logic, set is_delete in game_db.role_info
	local rpc_data = 
	{
		table_name = "role_info",
		fields = {is_delete = 1},
		conditions = {role_id = role_id}
	}
	local status, ret = Env.rpc_mgr:call_by_server_type(ServerType.DB, "db_game_update", rpc_data, role_id)
	if not status then
		Log.err("rpc_delete_role rpc call fail")
		return {result = ErrorCode.SYS_ERROR}
	end
	Log.debug("rpc_delete_role: callback ret=%s", Util.table_to_string(ret))

	return {result = ret.result}
end

function CommonMgr:get_free_gate()
	local gate_server_id = 0
	local min_conn_num = math.huge
	for k, v in pairs(self._gate_conn_map) do
		if v < min_conn_num then
			gate_server_id = k
			min_conn_num = v
		end
	end

	return gate_server_id
end

function CommonMgr:gen_user_token()
	return tostring(math.random(10000, 99999))
end

function CommonMgr:create_online_user(user_id, role_id)

	if self._online_user_map[user_id] then
		return nil
	end

	local gate_server_id = self:get_free_gate()
	if gate_server_id == 0 then
		return nil
	end

	local token = self:gen_user_token()

	local online_user = 
	{
		role_id = role_id,
		token = token,
		gate_server_id = gate_server_id,
	}

	self._online_user_map[user_id] = online_user

	return online_user
end

-- return table for rpc call
function CommonMgr:rpc_select_role(user_id, role_id)

	-- 1. check if exists online role, if true, rpc gate kick him
	-- 2. db load scene_id
	-- 3. rpc gate select role

	local server_id = 0
	local scene_id = 0
	
	local online_user = self._online_user_map[user_id]

	-- kick online user
	if online_user then
		Log.warn("CommonMgr:rpc_select_role user online user_id=%d role_id=%d", user_id, role_id)
		local rpc_data = 
		{
			user_id = user_id,
			role_id = role_id,
			reason = ErrorCode.ROLE_KICK_RELOGIN,
		}
		local status, ret = Env.rpc_mgr:call_by_server_id(online_user.gate_server_id, "gate_kick_role", rpc_data)
		if not status then
			Log.err("rpc_delete_role rpc call fail")
			return {result = ErrorCode.SYS_ERROR}
		end
		if ret.result ~= ErrorCode.SUCCESS then
			return {result = ret.result}
		end

		self._online_user_map[user_id] = nil
		server_id = ret.server_id
		scene_id = ret.scene_id
	end

	
	if server_id == 0 and scene_id == 0 then
		-- load scene_id from db
		local rpc_data = 
		{
			table_name = "role_info",
			fields = {"server_id", "scene_id"},
			conditions = {role_id = role_id}
		}
		local status, ret = Env.rpc_mgr:call_by_server_type(ServerType.DB, "db_game_select", rpc_data, role_id)
		if not status then
			Log.err("rpc_select_role rpc call fail")
			return {result = ErrorCode.SYS_ERROR}
		end
		Log.debug("rpc_select_role: callback ret=%s", Util.table_to_string(ret))

		if ret.result ~= ErrorCode.SUCCESS then
			return {result = ret.result}
		end

		if #ret.data ~= 1 or not ret.data[1].server_id or not ret.data[1].scene_id then
			Log.warn("rpc_select_role: role not exists %d %d", user_id, role_id)
			return {result = ErrorCode.ROLE_NOT_EXISTS}
		end
		server_id = ret.data[1].server_id
		scene_id = ret.data[1].scene_id
	end

	-- rpc gate select role
	online_user = self:create_online_user(user_id, role_id)
	if not online_user then
		Log.err("rpc_select_role create_online_user fail %d %d", user_id, role_id)
		return {result = ErrorCode.SYS_ERROR}
	end

	local token = online_user.token
	local rpc_data = 
	{
		user_id = user_id, 
		role_id = role_id, 
		server_id = server_id,
		scene_id = scene_id,
		token = token,
	}
	local status, ret = Env.rpc_mgr:call_by_server_id(online_user.gate_server_id, "gate_select_role", rpc_data)
	if not status then
		Log.err("rpc_select_role rpc call fail")
		return {result = ErrorCode.SYS_ERROR}
	end
	Log.debug("rpc_select_role: callback ret=%s", Util.table_to_string(ret))
	if ret.result ~= ErrorCode.SUCCESS then
		return {result = ret.result}
	end

	local msg = 
	{
		result = ErrorCode.SUCCESS,
		ip = ret.ip,
		port = ret.port,
		token = token,
	}

	return msg
end

function CommonMgr:rpc_user_offline(user_id)
	
	if not self._online_user_map[user_id] then
		Log.err("g_common_mgr:rpc_user_offline user nil user_id=%d", user_id)
		return
	end

	self._online_user_map[user_id] = nil
end

return CommonMgr
