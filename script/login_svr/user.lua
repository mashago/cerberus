
local User = {}

function User:new(mailbox_id, user_id, username, channel_id)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj._mailbox_id = mailbox_id
	obj._user_id = user_id
	obj._username = username
	obj._channel_id = channel_id

	return obj
end

function User:send_msg(msg_id, msg)
	return Net.send_msg(self._mailbox_id, msg_id, msg)
end

return User
