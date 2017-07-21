
local User = {}

function User:new(user_id, role_id, scene_id, token)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj._user_id = user_id
	obj._role_id = role_id
	obj._scene_id = scene_id
	obj._token = token

	obj._mailbox_id = 0
	obj._is_online = false

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

function User:delete_role(area_id, role_id)
	self._role_map[area_id] = self._role_map[area_id] or {}
	for k, v in ipairs(self._role_map[area_id]) do
		if v.role_id == role_id then
			table.remove(self._role_map[area_id], k)
		end
	end
end

return User
