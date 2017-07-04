
local User = {}

function User:new(mailbox_id, user_id, username, channel_id)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj._mailbox_id = mailbox_id
	obj._user_id = user_id
	obj._username = username
	obj._channel_id = channel_id
	obj._is_online = true
	obj._role_map = {} -- {[area_id]=role_list, }

	return obj
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
	self._role_map[area_id] = self._role_map[area_id] or {}
	local role = {role_id=role_id, role_name=role_name}
	table.insert(self._role_map[area_id], role)
end

return User
