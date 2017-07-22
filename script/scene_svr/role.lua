
local Role = {}

function Role:new(role_id, mailbox_id)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj._role_id = role_id
	obj._mailbox_id = mailbox_id -- router mailbox id

	return obj
end

function Role:send_msg(msg_id, msg)
	-- add role_id into ext
	return Net.send_msg_ext(self._mailbox_id, msg_id, self._role_id, msg)
end

return Role
