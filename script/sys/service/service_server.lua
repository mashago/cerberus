
ServiceServer = {}

-- all server map
-- {server_id = server_info, ...}
ServiceServer._all_server_map = {}

-- {server_type = {server_id, server_id, ...}
ServiceServer._type_server_map = {}

-- {scene_id = {server_id, server_id, ...}
ServiceServer._scene_server_map = {}

-- if is server, return server_id, else return nil
function ServiceServer.is_server(mailbox_id)
	for server_id, server_info in ipairs(ServiceServer._all_server_map) do
		if server_info._mailbox_id == mailbox_id then
			return server_id
		end
	end
	return nil
end

function ServiceServer.add_server(mailbox_id, server_id, server_type, single_list, from_to_list)

	local server_info = ServiceServer._all_server_map[server_id]
	if server_info then
		-- if exists in all_server_map, means add by other router, just update service_mailbox_list
		Log.warn("ServiceServer.add_server already add mailbox_id=%d server_id=%d", mailbox_id, server_id)
		return
	end

	-- init server_info
	server_info = {}
	server_info._server_id = server_id
	server_info._server_type = server_type
	server_info._mailbox_id = mailbox_id
	server_info._scene_list = {}
	for _, scene_id in ipairs(single_list) do
		table.insert(server_info._scene_list, scene_id)
	end
	for i=1, #from_to_list-1, 2 do
		local from = from_to_list[i]
		local to = from_to_list[i+1]
		for scene_id=from, to do
			table.insert(server_info._scene_list, scene_id)
		end
	end
	Log.debug("server_info._scene_list=%s", tableToString(server_info._scene_list))

	-- add into all_server_map
	ServiceServer._all_server_map[server_info._server_id] = server_info
	
	-- add into type_server_map
	ServiceServer._type_server_map[server_type] = ServiceServer._type_server_map[server_type] or {}
	table.insert(ServiceServer._type_server_map[server_type], server_id)

	-- add into scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		ServiceServer._scene_server_map[scene_id] = ServiceServer._scene_server_map[scene_id] or {}
		table.insert(ServiceServer._scene_server_map[scene_id], server_id)
	end

end

function ServiceServer.remove_server(server_id)

	local server_info = ServiceServer._all_server_map[server_id]
	if not server_info then
		Log.warn("ServiceServer.remove_server server nil server_id=%d", server_id)
		return
	end

	-- no more service connect to this server
	-- remove this server in type_server_map
	local type_server_list = ServiceServer._type_server_map[server_info._server_type] or {}
	for i=#type_server_list, 1, -1 do
		if type_server_list[i] == server_id then
			table.remove(type_server_list, i)
		end
	end

	-- remove this server in scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		local scene_server_list = ServiceServer._scene_server_map[scene_id]
		for i=#scene_server_list, 1, -1 do
			table.remove(scene_server_list, i)
		end
	end

	-- remove this server in all_server_map
	ServiceServer._all_server_map[server_id] = nil
end

return ServiceServer
