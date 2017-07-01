
local ServerInfo = {}

function ServerInfo:new(server_id, server_type, mailbox_id, single_scene_list, from_to_scene_list, is_secondhand)
	local obj = {}	
	setmetatable(obj, self)
	self.__index = self

	obj._server_id = server_id
	obj._server_type = server_type

	obj._mailbox_id = -1 -- default -1
	obj._secondhand_mailbox_id = {}

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

return ServerInfo
