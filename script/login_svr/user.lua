
local User = class()

function User:ctor(mailbox_id, user_id, username, channel_id)
	self._mailbox_id = mailbox_id
	self._user_id = user_id
	self._username = username
	self._channel_id = channel_id
	self._is_online = true

	--[[
	{
		[area_id]= 
		{
			{role_id=x, role_name=y},
			{role_id=x, role_name=y},
		},
	}
	--]]
	self._role_map = nil 
end

function User:is_ok()
	if not self._is_online then
		return false
	end
	return true
end

function User:send_msg(msg_id, msg)
	if not self._is_online then
		return false
	end
	return Net.send_msg(self._mailbox_id, msg_id, msg)
end

function User:add_role(area_id, role_id, role_name)
	self._role_map = self._role_map or {} 
	self._role_map[area_id] = self._role_map[area_id] or {}
	local role = {role_id=role_id, role_name=role_name}
	table.insert(self._role_map[area_id], role)
end

------------------------

function User:_db_get_role_list()
	local rpc_data = 
	{
		table_name = "user_role",
		fields = {"role_id", "role_name, area_id"},
		conditions=
		{
			user_id = self._user_id, 
			is_delete = 0,
		}
	}
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_login_select", rpc_data)
	if not status then
		Log.err("handle_role_list_req rpc call fail")
		return false, ErrorCode.SYS_ERROR
	end
	Log.debug("handle_role_list_req: callback ret=%s", Util.table_to_string(ret))
	return ret
end

function User:_db_create_role(area_id, role_name)
	local rpc_data = 
	{
		user_id=self._user_id, 
		area_id=area_id, 
		role_name=role_name,
		max_role=5,
	}
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_create_role", rpc_data, self._user_id)
	if not status then
		return false, ErrorCode.SYS_ERROR
	end
	Log.debug("_db_create_role: callback ret=%s", Util.table_to_string(ret))

	if ret.result ~= ErrorCode.SUCCESS then
		return false, ret.result
	end

	return ret
end

function User:_area_create_role(area_id, role_id, role_name)
	local server_id = g_area_mgr:get_server_id(area_id)
	local rpc_data = 
	{
		role_id=role_id,
		role_name=role_name,
		user_id=self._user_id, 
		channel_id=self._channel_id, 
		area_id=area_id, 
	}
	local status, ret = g_rpc_mgr:call_by_server_id(server_id, "bridge_create_role", rpc_data)
	if not status then
		Log.err("_area_create_role rpc call fail")
		-- delete in user_role
		local rpc_data =
		{
			table_name = "user_role",
			conditions = {role_id = role_id},
		}
		g_rpc_mgr:call_nocb_by_server_type(ServerType.DB, "db_login_delete", rpc_data, self._user_id)

		return false, ErrorCode.CREATE_ROLE_FAIL
	end
	Log.debug("_area_create_role: ret=%s", Util.table_to_string(ret))

	return true
end

function User:_check_role_exists(area_id, role_id)
	-- check already get role_list
	local role_list = self._role_map[area_id]
	if not role_list then
		return false
	end

	-- check role exists
	local is_exists = false
	for k, v in ipairs(role_list) do
		if v.role_id == role_id then
			is_exists = true
			break
		end
	end
	if not is_exists then
		return false
	end
	return true
end

function User:_area_delete_role(area_id, role_id)
	local server_id = g_area_mgr:get_server_id(area_id)
	local rpc_data = 
	{
		user_id=self._user_id,
		role_id=role_id,
	}
	local status, ret = g_rpc_mgr:call_by_server_id(server_id, "bridge_delete_role", rpc_data)
	if not status then
		return false, ErrorCode.DELETE_ROLE_FAIL
	end
	Log.debug("_area_delete_role: callback ret=%s", Util.table_to_string(ret))
	if ret.result ~= ErrorCode.SUCCESS then
		return false, ret.result
	end

	return ret
end

function User:_db_delete_role(role_id)
	local rpc_data = 
	{
		table_name="user_role",
		fields={is_delete = 1},
		conditions={role_id=role_id}
	}
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_login_update", rpc_data)
	if not status then
		Log.err("_db_delete_role rpc call fail")
		return false, ErrorCode.DELETE_ROLE_FAIL
	end
	Log.debug("_db_delete_role: callback ret=%s", Util.table_to_string(ret))

	if ret.result ~= ErrorCode.SUCCESS then
		return false, ret.result
	end

	return ret
end

function User:_area_select_role(area_id, role_id)
	local server_id = g_area_mgr:get_server_id(area_id)
	local rpc_data = 
	{
		user_id=self._user_id,
		role_id=role_id,
	}
	local status, ret = g_rpc_mgr:call_by_server_id(server_id, "bridge_select_role", rpc_data)
	if not status then
		Log.err("User:_area_select_role rpc call fail")
		return false, ErrorCode.SELECT_ROLE_FAIL
	end
	Log.debug("User:_area_select_role callback ret=%s", Util.table_to_string(ret))
	if ret.result ~= ErrorCode.SUCCESS then
		return false, ret.result
	end

	return ret
end

---------------------------------------------

function User:send_role_list()
	local msg =
	{
		result = ErrorCode.SUCCESS,
		area_role_list = {},
	}
	for area_id, role_list in pairs(self._role_map) do
		local node = {}
		node.area_id = area_id
		node.role_list = role_list
		table.insert(msg.area_role_list, node)
	end
	self:send_msg(MID.s2c_role_list_ret, msg)
end

function User:get_role_list()
	if self._lock_get_role_list then
		return
	end

	local msg =
	{
		result = ErrorCode.SUCCESS,
		area_role_list = {},
	}

	if self._role_map then
		self:send_role_list()
		return
	end

	self._lock_get_role_list = true
	local ret, err
	repeat
		ret, err = self:_db_get_role_list()
		if not ret then
			break
		end

		self._role_map = {}
		for _, v in ipairs(ret.data) do
			
			local role_id = tonumber(v.role_id)
			local role_name = v.role_name
			local area_id = tonumber(v.area_id)

			self:add_role(area_id, role_id, role_name)
		end
	until true
	self._lock_get_role_list = nil
	if err then
		msg.result = err
		self:send_msg(MID.s2c_role_list_ret, msg)
		return
	end

	self:send_role_list()
end

function User:create_role(area_id, role_name)
	if self._lock_create then
		return
	end

	self._lock_create = true
	local msg =
	{
		result = ErrorCode.SUCCESS,
		role_id = 0,
	}
	local ret, err
	repeat
		if not g_area_mgr:is_open(area_id) then
			err = ErrorCode.AREA_NOT_OPEN
			break
		end
		-- check already get role_list
		if not self._role_map then
			err = ErrorCode.CREATE_ROLE_FAIL
			break
		end

		-- rpc to db create role
		ret, err = self:_db_create_role(area_id, role_name)
		if not ret then
			break
		end
		local role_id = ret.role_id

		-- rpc to area bridge to create role data
		ret, err = self:_area_create_role(area_id, role_id, role_name)
		if not ret then
			break
		end

		-- add role into user
		self:add_role(area_id, role_id, role_name)
		msg.role_id = role_id
	until true
	self._lock_create = nil
	if err then
		msg.result = err
	end
	self:send_msg(MID.s2c_create_role_ret, msg)
	if not err then
		self:send_role_list()
	end
end

function User:delete_role(area_id, role_id)
	if self._lock_delete then
		return
	end

	self._lock_delete = true
	local msg =
	{
		result = ErrorCode.SUCCESS,
		role_id = role_id,
	}
	local ret, err
	repeat
		if not g_area_mgr:is_open(area_id) then
			err = ErrorCode.AREA_NOT_OPEN
			break
		end

		ret = self:_check_role_exists(area_id, role_id)
		if not ret then
			err = ErrorCode.DELETE_ROLE_FAIL
			break
		end

		-- rpc to area bridge to delete role
		ret, err = self:_area_delete_role(area_id, role_id)
		if not ret then
			break
		end

		ret, err = self:_db_delete_role(role_id)
		if not ret then
			break
		end

		-- local delete role
		self._role_map[area_id] = self._role_map[area_id] or {}
		for k, v in ipairs(self._role_map[area_id]) do
			if v.role_id == role_id then
				table.remove(self._role_map[area_id], k)
			end
		end
	until true
	self._lock_delete = nil
	if err then
		msg.result = err
	end
	self:send_msg(MID.s2c_delete_role_ret, msg)

end

function User:select_role(area_id, role_id)
	if self._lock_select then
		return
	end

	self._lock_select = true

	local msg =
	{
		result = ErrorCode.SUCCESS,
		ip = "",
		port = 0,
		user_id = self._user_id,
		token = "",
	}
	local ret, err
	repeat
		if not g_area_mgr:is_open(area_id) then
			err = ErrorCode.AREA_NOT_OPEN
			break
		end

		-- check role exists
		ret = self:_check_role_exists(area_id, role_id)
		if not ret then
			err = ErrorCode.SELECT_ROLE_FAIL
			break
		end

		-- rpc to area bridge
		ret, err = self:_area_select_role(area_id, role_id)
		if not ret then
			break
		end

		if not self:is_ok() then
			-- user may offline, XXX need to send to area?
			err = ErrorCode.SELECT_ROLE_FAIL
			break
		end
		
	until true
	self._lock_select = nil

	if err then
		msg.result = err
	else
		msg.ip = ret.ip
		msg.port = ret.port
		msg.user_id = self._user_id
		msg.token = ret.token
	end
	self:send_msg(MID.s2c_select_role_ret, msg)
end

return User
