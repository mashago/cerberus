
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

function User:core_delete_role(area_id, role_id)
	self._role_map[area_id] = self._role_map[area_id] or {}
	for k, v in ipairs(self._role_map[area_id]) do
		if v.role_id == role_id then
			table.remove(self._role_map[area_id], k)
		end
	end
end

function User:_check_role_exists(area_id, role_id)
	-- 1. check already get role_list
	local role_list = self._role_map[area_id]
	if not role_list then
		return false
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
		return false
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
		return false
	end
	Log.debug("handle_delete_role: callback ret=%s", Util.table_to_string(ret))
	if ret.result ~= ErrorCode.SUCCESS then
		return false
	end

	return true
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
		return false
	end
	Log.debug("handle_delete_role: callback ret=%s", Util.table_to_string(ret))

	if ret.result ~= ErrorCode.SUCCESS then
		return false
	end

	return true
end

function User:delete_role(area_id, role_id)
	local ret, err
	repeat
		if self._lock_delete then
			break
		end
		self._lock_delete = true

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
		self:core_delete_role(area_id, role_id)
	until true
	self._lock_delete = nil
end

return User
