
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
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_game_insert", rpc_data)
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
	local enter_user = self._online_user_map[user_id]
	if enter_user and enter_user.role_id == role_id then
		-- rpc to gate, kick role
		local rpc_data = 
		{
			user_id = user_id,
			role_id = role_id,
		}
		local status, ret = g_rpc_mgr:call_by_server_id(enter_user.gate_server_id, "gate_kick_role", rpc_data)
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
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_game_update", rpc_data)
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

function CommonMgr:create_enter_user(user_id, role_id)

	local enter_user = self._online_user_map[user_id]

	local gate_server_id = 0
	if enter_user then
		-- duplicate select role
		-- use old gate
		gate_server_id = enter_user.gate_server_id
	else
		gate_server_id = self:get_free_gate()
	end

	if gate_server_id == 0 then
		return nil
	end

	local token = self:gen_user_token()

	enter_user = 
	{
		role_id = role_id,
		token = token,
		gate_server_id = gate_server_id,
	}

	self._online_user_map[user_id] = enter_user

	return enter_user
end

-- return table for rpc call
function CommonMgr:rpc_select_role(user_id, role_id)

	-- load scene_id from db
	local rpc_data = 
	{
		table_name = "role_info",
		fields = {"scene_id"},
		conditions = {role_id=role_id}
	}
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_game_select", rpc_data)
	if not status then
		Log.err("rpc_select_role rpc call fail")
		return {result = ErrorCode.SYS_ERROR}
	end
	Log.debug("rpc_select_role: callback ret=%s", Util.table_to_string(ret))

	if ret.result ~= ErrorCode.SUCCESS then
		return {result = ret.result}
	end

	if #ret.data ~= 1 or not ret.data[1].scene_id then
		Log.warn("rpc_select_role: role not exists %d %d", user_id, role_id)
		return {result = ErrorCode.ROLE_NOT_EXISTS}
	end
	local scene_id = ret.data[1].scene_id

	-- rpc gate select role
	local enter_user = self:create_enter_user(user_id, role_id)
	if not enter_user then
		Log.err("rpc_select_role create_enter_user fail %d %d", user_id, role_id)
		return {result = ErrorCode.SYS_ERROR}
	end

	local token = enter_user.token
	local rpc_data = 
	{
		user_id=user_id, 
		role_id=role_id, 
		scene_id=scene_id,
		token=token,
	}
	local status, ret = g_rpc_mgr:call_by_server_id(enter_user.gate_server_id, "gate_select_role", rpc_data)
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
		result=ErrorCode.SUCCESS,
		ip=ret.ip,
		port=ret.port,
		token=token,
	}

	return msg
end

return CommonMgr
