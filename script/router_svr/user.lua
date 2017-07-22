
local User = {}

function User:new(user_id, role_id, scene_id, token)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj._user_id = user_id
	obj._role_id = role_id
	obj._scene_id = scene_id
	obj._token = token

	obj._scene_server_id = 0
	obj._mailbox_id = 0

	return obj
end

function User:disconnect()
	self._mailbox_id = 0
	local scene_server_info = ServiceMgr.get_server_by_id(self._scene_server_id)
	if not scene_server_info then
		Log.err("User:disconnect: scene server not exists scene_id=%d", self._scene_server_id)
		return
	end
	local msg = { }
	scene_server_info:send_msg_ext(MID.ROUTER_ROLE_DISCONNECT, self._role_id, msg)
end

return User
