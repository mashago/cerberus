
local ServerInfo = {}

function ServerInfo:new(server_id, server_type, mailbox_id, single_scene_list, from_to_scene_list, is_secondhand)
	local obj = {}	
	setmetatable(obj, self)
	self.__index = self

	obj._server_id = server_id
	obj._server_type = server_type

	obj._mailbox_id = -1 -- default -1
	obj._secondhand_mailbox_id = {} -- indirect mailbox id

	if not is_secondhand then
		obj._mailbox_id = mailbox_id
	else
		obj._secondhand_mailbox_id = {mailbox_id}
	end

	obj._single_scene_list = single_scene_list
	obj._from_to_scene_list = from_to_scene_list

	obj._scene_list = {}
	for _, scene_id in ipairs(single_scene_list) do
		table.insert(obj._scene_list, scene_id)
	end
	for i=1, #from_to_scene_list-1, 2 do
		local from = from_to_scene_list[i]
		local to = from_to_scene_list[i+1]
		for scene_id=from, to do
			table.insert(obj._scene_list, scene_id)
		end
	end

	return obj
end

-- get a mailbox to send msg
-- use _mailbox_id first, it is direct connect
-- if _mailbox_id not exists, random one from _secondhand_mailbox_id
function ServerInfo:get_mailbox_id()
	if self._mailbox_id ~= -1 then
		return self._mailbox_id
	end

	local len = #self._secondhand_mailbox_id
	if len == 0 then
		return -1
	end

	local r = math.random(len)
    local mailbox_id = self._secondhand_mailbox_id[r]
	
	return mailbox_id
end

function ServerInfo:send_msg(msg_id, msg)
	local mailbox_id = self:get_mailbox_id()
	if mailbox_id == -1 then
		Log.warn("ServerInfo:send_msg mailbox nil msg_id=%d", msg_id)
		return false
	end
	return Net.send_msg(mailbox_id, msg_id, msg)
end

function ServerInfo:print()
	Log.info("ServerInfo:print _server_id=%d _server_type=%d _mailbox_id=%d \n_secondhand_mailbox_id=%s \n_single_scene_list=%s \n_from_to_scene_list=%s", self._server_id,
	self._server_type,
	self._mailbox_id,
	Util.table_to_string(self._secondhand_mailbox_id),
	Util.table_to_string(self._single_scene_list),
	Util.table_to_string(self._from_to_scene_list)
	)
end

return ServerInfo

