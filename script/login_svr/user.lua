
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
	-- Log.warn("User:send_msg() xxxxxxxxxxxxxxxx")
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
		if not self._role_map then
			err = ErrorCode.CREATE_ROLE_FAIL
			break
		end

	until true
	self._lock_create = nil
	if err then
		msg.result = err
	end
	self:send_msg(MID.CREATE_ROLE_RET, msg)
end

------------------------

function User:_check_role_exists(area_id, role_id)
	-- 1. check already get role_list
	local role_list = self._role_map[area_id]
	if not role_list then
		return false, ErrorCode.DELETE_ROLE_FAIL
	end

	-- 2. check role exists
	local is_exists = false
	for k, v in ipairs(role_list) do
		if v.role_id == role_id then
			is_exists = true
			break
		end
	end
	if not is_exists then
		return false, ErrorCode.DELETE_ROLE_FAIL
	end
	return true
end

function User:_area_delete_role(area_id, role_id)
	-- 3. rpc to area bridge to delete role
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
		Log.err("handle_delete_role rpc call fail")
		return false, ErrorCode.DELETE_ROLE_FAIL
	end
	Log.debug("_db_delete_role: callback ret=%s", Util.table_to_string(ret))

	if ret.result ~= ErrorCode.SUCCESS then
		return false, ret.result
	end

	return ret
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

		ret, err = self:_check_role_exists(area_id, role_id)
		if not ret then
			break
		end
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
	self:send_msg(MID.DELETE_ROLE_RET, msg)

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

		-- 1. check role exists
		local role_list = self._role_map[area_id]
		if not role_list then
			err = ErrorCode.SELECT_ROLE_FAIL
			break
		end

		local is_exists = false
		for k, v in ipairs(role_list) do
			if v.role_id == role_id then
				is_exists = true
				break
			end
		end
		if not is_exists then
			err = ErrorCode.SELECT_ROLE_FAIL
			break
		end

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
	self:send_msg(MID.SELECT_ROLE_RET, msg)
end

return User
