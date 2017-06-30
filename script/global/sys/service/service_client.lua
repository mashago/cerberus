
ServiceClient = {}

-- all connect-to service server
-- {service_info, service_info, ...}
ServiceClient._all_service_server = {} 

-- all server map
-- {server_id = server_info, ...}
ServiceClient._all_server_map = {}

-- {server_type = {server_id, server_id, ...}
ServiceClient._type_server_map = {}

-- {scene_id = {server_id, server_id, ...}
ServiceClient._scene_server_map = {}

ServiceClient._is_connect_timer_running = false
ServiceClient._connect_interval_ms = 2000

function ServiceClient.is_service_server(mailbox_id)
	for _, service_info in pairs(ServiceClient._all_service_server) do
		if service_info._mailbox_id == mailbox_id then
			return true
		end
	end
	return false
end

function ServiceClient.add_connect_service(ip, port, server_id, server_type, register)
	local service_info = 
	{
		_server_id = server_id or 0, 
		_server_type = server_type or 0, 
		_ip = ip, 
		_port = port, 
		-- _desc = desc, 
		_mailbox_id = 0,
		_register = register,
		_is_connecting = false,
		_is_connected = false,
		_last_connect_time = 0,
		_server_list = {}, -- {server_id1, server_id2}
	}
	table.insert(ServiceClient._all_service_server, service_info)
end

function ServiceClient.create_connect_timer()

	local function timer_cb(arg)
		Log.debug("ServiceClient timer_cb")
		-- Log.debug("handle_client_test: ServiceClient._all_service_server=%s", Util.TableToString(ServiceClient._all_service_server))
		local now_time = os.time()
		
		local is_all_connected = true
		for _, service_info in ipairs(ServiceClient._all_service_server) do
			if not service_info._is_connected then
				is_all_connected = false
				if not service_info._is_connecting then
					Log.debug("connect to ip=%s port=%d", service_info._ip, service_info._port)
					local ret, mailbox_id = g_network:connect_to(service_info._ip, service_info._port)
					-- Log.debug("ret=%s mailbox_id=%d", ret and "true" or "false", mailbox_id)
					if ret then
						service_info._mailbox_id = mailbox_id
						service_info._is_connecting = true
						service_info._last_connect_time = now_time
					else
						Log.warn("******* connect to fail ip=%s port=%d", service_info._ip, service_info._port)
					end
				else
					Log.debug("connecting mailbox_id=%d ip=%s port=%d", service_info._mailbox_id, service_info._ip, service_info._port)
					if now_time - service_info._last_connect_time > 5 then
						-- connect time too long, close this connect
						Log.warn("!!!!!!! connecting timeout mailbox_id=%d ip=%s port=%d", service_info._mailbox_id, service_info._ip, service_info._port)
						g_network:close_mailbox(service_info._mailbox_id) -- will cause luaworld:HandleDisconnect
						service_info._mailbox_id = 0 
						service_info._is_connecting = false
					end
				end
			end
		end
		if is_all_connected then
			Log.debug("******* all connect *******")
			Timer.del_timer(ServiceClient._connect_timer_index)
			ServiceClient._is_connect_timer_running = false
		end
	end

	ServiceClient._is_connect_timer_running = true
	ServiceClient._connect_timer_index = Timer.add_timer(ServiceClient._connect_interval_ms, timer_cb, 0, true)
end

--------------------------------------------------

function ServiceClient.get_service(mailbox_id)
	for _, service_info in ipairs(ServiceClient._all_service_server) do
		if service_info._mailbox_id == mailbox_id then
			return service_info
		end
	end
	return nil
end

function ServiceClient.add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	for _, service_info in ipairs(ServiceClient._all_service_server) do
		if service_info._mailbox_id == mailbox_id then
			table.insert(service_info._server_list, server_id)
			break
		end
	end

	local server_info = ServiceClient._all_server_map[server_id]
	if server_info then
		-- if exists in all_server_map, means add by other router, just update service_mailbox_list
		for k, v in ipairs(server_info._service_mailbox_list) do
			if v == mailbox_id then
				Log.err("ServiceClient.service_add_connect_server add duplicate mailbox_id=%d server_id=%d", mailbox_id, server_id)
				return
			end
		end
		table.insert(server_info._service_mailbox_list, mailbox_id)
		ServiceClient.print()
		return
	end

	-- init server_info
	server_info = {}
	server_info._server_id = server_id
	server_info._server_type = server_type
	server_info._service_mailbox_list = {mailbox_id}
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
	ServiceClient._all_server_map[server_info._server_id] = server_info
	
	-- add into type_server_map
	ServiceClient._type_server_map[server_type] = ServiceClient._type_server_map[server_type] or {}
	table.insert(ServiceClient._type_server_map[server_type], server_id)

	-- add into scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		ServiceClient._scene_server_map[scene_id] = ServiceClient._scene_server_map[scene_id] or {}
		table.insert(ServiceClient._scene_server_map[scene_id], server_id)
	end

	ServiceClient.print()
end

function ServiceClient._remove_server_core(mailbox_id, server_id)

	-- 1. server_info remove service mailbox
	-- 2. remove from type_server_map
	-- 3. remove from scene_server_map

	-- 1. server_info remove service mailbox
	local server_info = ServiceClient._all_server_map[server_id]
	for i=#server_info._service_mailbox_list, 1, -1 do
		if server_info._service_mailbox_list[i] == mailbox_id then
			table.remove(server_info._service_mailbox_list, i)
		end
	end
	
	if #server_info._service_mailbox_list > 0 then
		-- still has service connect to this server, do nothing
		return
	end

	-- 2. remove from type_server_map
	-- no more service connect to this server
	-- remove this server in type_server_map
	local type_server_list = ServiceClient._type_server_map[server_info._server_type] or {}
	for i=#type_server_list, 1, -1 do
		if type_server_list[i] == server_id then
			table.remove(type_server_list, i)
		end
	end
	if #type_server_list == 0 then
		-- no more type server, clean up
		ServiceClient._type_server_map[server_info._server_type] = nil
	end

	-- 3. remove from scene_server_map
	-- remove this server in scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		local scene_server_list = ServiceClient._scene_server_map[scene_id]
		for i=#scene_server_list, 1, -1 do
			table.remove(scene_server_list, i)
		end
		if #scene_server_list == 0 then
			-- no more scene server, clean up
			ServiceClient._scene_server_map[scene_id] = nil
		end
	end

	-- remove this server in all_server_map
	ServiceClient._all_server_map[server_id] = nil
end

function ServiceClient.remove_server(mailbox_id, server_id)

	-- 1. service_info remove server_id in server_list
	-- 2. remove server core

	local service_info = ServiceClient.get_service(mailbox_id)
	if not service_info then
		Log.err("ServiceClient.remove_server2 service nil mailbox_id=%d", mailbox_id)
		return
	end
	
	-- 1. service_info remove server_id in server_list
	for i=1, #service_info._server_list do
		if service_info._server_list[i] == server_id then
			table.remove(service_info._server_list, i)
		end
	end

	-- 2. remove server core
	ServiceClient._remove_server_core(mailbox_id, server_id)

	ServiceClient.print()
end

function ServiceClient.handle_disconnect(mailbox_id)
	Log.info("ServiceClient.handle_disconnect mailbox_id=%d", mailbox_id)

	for _, service_info in ipairs(ServiceClient._all_service_server) do
		if service_info._mailbox_id == mailbox_id then
			-- set disconnect
			service_info._mailbox_id = -1
			service_info._is_connecting = false
			service_info._is_connected = false

			for _, server_id in ipairs(service_info._server_list) do
				ServiceClient._remove_server_core(mailbox_id, server_id)
			end
			service_info._server_list = {}

			break
		end
	end

	if ServiceClient._is_connect_timer_running then
		-- do nothing, connect timer will do reconnect
		-- Log.debug("connect timer is running")
		return
	end

	-- connect timer already close, start it
	ServiceClient.create_connect_timer()

	ServiceClient.print()
end

function ServiceClient.connect_to_success(mailbox_id)
	local service_info = ServiceClient.get_service(mailbox_id)
	if not service_info then
		Log.err("ServiceClient.connect_to_success service nil %d", mailbox_id)
		return
	end
	-- of course is trust
	Net.add_mailbox(mailbox_id, ConnType.TRUST)

	service_info._is_connecting = false
	service_info._is_connected = true

	if service_info._register == 1 then
		-- need register, send register msg
		local msg = {}
		msg[1] = ServerConfig._server_id
		msg[2] = ServerConfig._server_type
		msg[3] = ServerConfig._single_scene_list
		msg[4] = ServerConfig._from_to_scene_list
		Net.send_msg(mailbox_id, MID.REGISTER_SERVER_REQ, table.unpack(msg))
		ServiceClient.print()
	else
		ServiceClient.add_server(mailbox_id, service_info._server_id, service_info._server_type, {}, {})
	end
end

function ServiceClient.register_success(mailbox_id, server_id, server_type)
	local service_info = ServiceClient.get_service(mailbox_id)
	if not service_info then
		Log.err("ServiceClient.register_success service nil %d %d %d", server_id, server_type)
		return
	end

	service_info._server_id = server_id
	service_info._server_type = server_type

	-- add service as a server too
	ServiceClient.add_server(mailbox_id, server_id, server_type, {}, {})

	-- ServiceClient.print()
end

function ServiceClient.get_server_by_id(server_id)
	
    local server_info = ServiceClient._all_server_map[server_id]
    if not server_info then
        return nil
    end

	if #server_info._service_mailbox_list == 0 then
		return nil
	end

	local r = math.random(#server_info._service_mailbox_list)
    local mailbox_id = server_info._service_mailbox_list[r]
    if mailbox_id == 0 then
        return nil
    end

	return {mailbox_id=mailbox_id, server_id=server_id}
end

-- same opt_key(number) will get same server, or just do random to get
function ServiceClient.get_server_by_type(server_type, opt_key)
	
	local id_list = {}
	local id_list = ServiceClient._type_server_map[server_type] or {}
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

	return ServiceClient.get_server_by_id(server_id)
end

-- luaclient use this now
function ServiceClient.send_to_type_server(server_type, msg_id, ...)
	local server = ServiceClient.get_server_by_type(server_type)
	if not server then
		return false
	end

    Net.send_msg(server.mailbox_id, msg_id, ...)
end

function ServiceClient.print()
	Log.info("*********ServiceClient********")
	Log.info("ServiceClient._all_service_server=%s", Util.TableToString(ServiceClient._all_service_server))
	Log.info("ServiceClient._all_server_map=%s", Util.TableToString(ServiceClient._all_server_map))
	Log.info("ServiceClient._type_server_map=%s", Util.TableToString(ServiceClient._type_server_map))
	Log.info("ServiceClient._scene_server_map=%s", Util.TableToString(ServiceClient._scene_server_map))
	Log.info("******************************")
end

return ServiceClient
