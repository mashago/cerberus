
ServiceServer = {}

-- all server map
-- {server_id = server_info, ...}
ServiceServer._all_server_map = {}

-- {server_type = {server_id, server_id, ...}
ServiceServer._type_server_map = {}

-- {scene_id = {server_id, server_id, ...}
ServiceServer._scene_server_map = {}

function ServiceServer.is_service_client(mailbox_id)
	for server_id, server_info in pairs(ServiceServer._all_server_map) do
		if server_info._mailbox_id == mailbox_id then
			return true
		end
	end
	return false
end

function ServiceServer.add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

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
	server_info._single_scene_list = single_scene_list
	server_info._from_to_scene_list = from_to_scene_list
	server_info._scene_list = {}
	for _, scene_id in ipairs(single_scene_list) do
		table.insert(server_info._scene_list, scene_id)
	end
	for i=1, #from_to_scene_list-1, 2 do
		local from = from_to_scene_list[i]
		local to = from_to_scene_list[i+1]
		for scene_id=from, to do
			table.insert(server_info._scene_list, scene_id)
		end
	end
	-- Log.debug("server_info._scene_list=%s", Util.TableToString(server_info._scene_list))

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

	ServiceServer.print()
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
	if #type_server_list == 0 then
		ServiceServer._type_server_map[server_info._server_type] = nil
	end
	

	-- remove this server in scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		local scene_server_list = ServiceServer._scene_server_map[scene_id]
		for i=#scene_server_list, 1, -1 do
			if scene_server_list[i] == server_id then
				table.remove(scene_server_list, i)
			end
		end
		if #scene_server_list == 0 then
			ServiceServer._scene_server_map[scene_id] = nil
		end
	end

	-- remove this server in all_server_map
	ServiceServer._all_server_map[server_id] = nil
end

function ServiceServer.service_client_disconnect(mailbox_id)
	local disconnect_server_id = 0
	for server_id, server_info in pairs(ServiceServer._all_server_map) do
		if server_info._mailbox_id == mailbox_id then
			disconnect_server_id = server_info._server_id
			ServiceServer.remove_server(server_info._server_id)
			break
		end
	end

	for _, server_info in pairs(ServiceServer._all_server_map) do
		Net.send_msg(server_info._mailbox_id, MID.SERVER_DISCONNECT, disconnect_server_id)
	end

	ServiceServer.print()
end

function ServiceServer.get_server_by_scene(scene_id)
	
	local id_list = {}
	local id_list = ServiceServer._scene_server_map[scene_id] or {}
	if #id_list == 0 then
		return nil
	end

	local r = math.random(#id_list)
	local server_id = id_list[r]

    local server_info = ServiceServer._all_server_map[server_id]
    if not server_info then
        return nil
    end

    local mailbox_id = server_info._mailbox_id
    if mailbox_id == 0 then
        return nil
    end

	return {mailbox_id=mailbox_id, server_id=server_id}
end

function ServiceServer.print()
	Log.info("---------ServiceServer--------")
	Log.info("ServiceServer._all_server_map=%s", Util.TableToString(ServiceServer._all_server_map))
	Log.info("ServiceServer._type_server_map=%s", Util.TableToString(ServiceServer._type_server_map))
	Log.info("ServiceServer._scene_server_map=%s", Util.TableToString(ServiceServer._scene_server_map))
	Log.info("------------------------------")
end

return ServiceServer
