
local ServerInfo = class()

function ServerInfo:ctor(server_id, server_type, mailbox_id, single_scene_list, from_to_scene_list)

	self._server_id = server_id
	self._server_type = server_type

	self._mailbox_id = mailbox_id

	self._single_scene_list = single_scene_list
	self._from_to_scene_list = from_to_scene_list

	self._scene_list = {}
	for _, scene_id in ipairs(single_scene_list) do
		table.insert(self._scene_list, scene_id)
	end
	for i=1, #from_to_scene_list-1, 2 do
		local from = from_to_scene_list[i]
		local to = from_to_scene_list[i+1]
		for scene_id=from, to do
			table.insert(self._scene_list, scene_id)
		end
	end

end

-- get a mailbox to send msg
function ServerInfo:get_mailbox_id()
	return self._mailbox_id
end

function ServerInfo:send_msg(msg_id, msg)
	return self:send_msg_ext(msg_id, 0, msg)
end

function ServerInfo:send_msg_ext(msg_id, ext, msg)
	local mailbox_id = self:get_mailbox_id()
	if mailbox_id == -1 then
		Log.warn("ServerInfo:send_msg mailbox nil msg_id=%d", msg_id)
		return false
	end
	return Net.send_msg_ext(mailbox_id, msg_id, ext, msg)
end

function ServerInfo:transfer_msg(ext)
	local mailbox_id = self:get_mailbox_id()
	if mailbox_id == -1 then
		Log.warn("ServerInfo:send_msg mailbox nil msg_id=%d", msg_id)
		return false
	end
	return Net.transfer_msg(mailbox_id, ext)
end

function ServerInfo:print()
	Log.info("------ServerInfo--------")
	Log.info("ServerInfo _server_id=%d _server_type=%d _mailbox_id=%d", self._server_id, self._server_type, self._mailbox_id)
	Log.info("ServerInfo._single_scene_list=%s", Util.table_to_string(self._single_scene_list))
	Log.info("ServerInfo._from_to_scene_list=%s", Util.table_to_string(self._from_to_scene_list))
	Log.info("--------------")
end

return ServerInfo

