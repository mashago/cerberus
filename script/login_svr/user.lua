
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
	self._role_map[area_id] = self._role_map[area_id] or {}
	local role = {role_id=role_id, role_name=role_name}
	table.insert(self._role_map[area_id], role)
end

function User:delete_role(area_id, role_id)
	self._role_map[area_id] = self._role_map[area_id] or {}
	for k, v in ipairs(self._role_map[area_id]) do
		if v.role_id == role_id then
			table.remove(self._role_map[area_id], k)
		end
	end
end

return User
