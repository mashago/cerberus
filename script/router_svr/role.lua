
local Role = {}

function Role:new(role_id, user_id, mailbox_id, scene_server_id)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj._role_id = role_id
	obj._user_id = user_id
	obj._mailbox_id = mailbox_id
	obj._scene_server_id = scene_server_id

	return obj
end

function Role:send_msg(msg_id, msg)
	return Net.send_msg(self._mailbox_id, msg_id, msg)
end

return Role
