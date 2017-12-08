
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
		-- if exists in all_server_map, duplicate add
		Log.err("ServiceServer.add_server already add mailbox_id=%d server_id=%d", mailbox_id, server_id)
		return nil
	end

	-- init server_info
	local ServerInfo = require "global.service.server_info"
	local server_info = ServerInfo:new(server_id, server_type, mailbox_id, single_scene_list, from_to_scene_list)
	-- Log.debug("server_info._scene_list=%s", Util.table_to_string(server_info._scene_list))

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

	Log.info("ServiceServer.add_server:")
	ServiceServer.print()

	return server_info
end

function ServiceServer.remove_server(server_info)

	-- remove this server in type_server_map
	local type_server_list = ServiceServer._type_server_map[server_info._server_type] or {}
	for i=#type_server_list, 1, -1 do
		if type_server_list[i] == server_info._server_id then
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
			if scene_server_list[i] == server_info._server_id then
				table.remove(scene_server_list, i)
			end
		end
		if #scene_server_list == 0 then
			ServiceServer._scene_server_map[scene_id] = nil
		end
	end

	-- remove this server in all_server_map
	ServiceServer._all_server_map[server_info._server_id] = nil
end

function ServiceServer.handle_disconnect(mailbox_id)

	local server_info = ServiceServer.get_server_by_mailbox(mailbox_id)
	if not server_info then
		return
	end

	local disconnect_server_id = server_info._server_id
	ServiceServer.remove_server(server_info)

	if not ServerConfig._no_broadcast then
		for _, server_info in pairs(ServiceServer._all_server_map) do
			local msg =
			{
				server_id = disconnect_server_id
			}
			server_info:send_msg(MID.SERVER_DISCONNECT, msg)
		end
	end

	Log.debug("ServiceServer.handle_disconnect:")
	ServiceServer.print()
end

function ServiceServer.get_server_by_id(server_id)
	return ServiceServer._all_server_map[server_id]
end

function ServiceServer.get_server_by_scene(scene_id)
	
	local id_list = {}
	local id_list = ServiceServer._scene_server_map[scene_id] or {}
	if #id_list == 0 then
		return nil
	end

	local r = math.random(#id_list)
	local server_id = id_list[r]

	return ServiceServer.get_server_by_id(server_id)
end

-- same opt_key(number) will get same server, or just do random to get
function ServiceServer.get_server_by_type(server_type, opt_key)
	
	local id_list = {}
	local id_list = ServiceServer._type_server_map[server_type] or {}
	if #id_list == 0 then
		return nil
	end

	local server_id = 0
	if not opt_key then
		local r = math.random(#id_list)
		server_id = id_list[r]
	else
		local r = opt_key % #id_list + 1
		server_id = id_list[r]
	end

	return ServiceServer.get_server_by_id(server_id)
end

function ServiceServer.get_server_by_mailbox(mailbox_id)
	for server_id, server_info in pairs(ServiceServer._all_server_map) do
		if server_info._mailbox_id == mailbox_id then
			return server_info
		end
	end

	return nil
end

function ServiceServer.print()
	Log.info("############# ServiceServer ###########")
	Log.info("ServiceServer._all_server_map=")
	for k, server_info in pairs(ServiceServer._all_server_map) do
		server_info:print()
	end
	Log.info("ServiceServer._type_server_map=%s", Util.table_to_string(ServiceServer._type_server_map))
	Log.info("ServiceServer._scene_server_map=%s", Util.table_to_string(ServiceServer._scene_server_map))
	Log.info("#######################################")
end

return ServiceServer
