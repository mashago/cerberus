
ServiceClient = class()

function ServiceClient:ctor()

	-- all connect-to service server
	-- {service_info, service_info, ...}
	self._service_server_info_list = {} 

	-- all server map
	-- {server_id = server_info, ...}
	self._all_server_map = {}

	-- {server_type = {server_id, server_id, ...}
	self._type_server_map = {}

	-- {scene_id = {server_id, server_id, ...}
	self._scene_server_map = {}

	self._connect_timer_index = 0
	self._connect_interval_ms = 2000
end

function ServiceClient:is_service_server(mailbox_id)
	for _, service_info in ipairs(self._service_server_info_list) do
		if service_info._mailbox_id == mailbox_id then
			return true
		end
	end
	return false
end

function ServiceClient:do_connect(ip, port, server_id, server_type, register, no_reconnect, no_delay)
	-- check duplicate connect service
	
	register = register or 0
	no_reconnect = no_reconnect or 0
	no_delay = no_delay or 0

	for k, v in ipairs(self._service_server_info_list) do
		if v._ip == ip and v.port == port then
			Log.warn("ServiceClient:do_connect duplicate add ip=%s port=%d", ip, port)
			return
		end
	end
	
	local ServiceServerInfo = require "core.service.service_server_info"
	local service_info = ServiceServerInfo.new(ip, port, server_id, server_type, register, no_reconnect)
	table.insert(self._service_server_info_list, service_info)
	if no_delay == 1 then
		self:connect_immediately()
	else
		self:create_connect_timer()
	end
end

function ServiceClient:_connect_core()

	Log.debug("ServiceClient:_connect_core")
	-- Log.debug("handle_client_test: self._service_server_info_list=%s", Util.table_to_string(self._service_server_info_list))
	local now_time = os.time()
	
	local is_all_connected = true
	for _, service_info in ipairs(self._service_server_info_list) do
		Log.debug("ServiceClient:_connect_core server_info ip=%s port=%d connect_status=%d", service_info._ip, service_info._port, service_info._connect_status)
		if service_info._connect_status == ServiceConnectStatus.CONNECTED then
			goto continue
		end

		is_all_connected = false
		-- not connecting, do connect
		if service_info._connect_status == ServiceConnectStatus.DISCONNECT then
			Log.debug("connect to ip=%s port=%d", service_info._ip, service_info._port)
			-- only return a connect_index, get mailbox_id later
			local ret, connect_index = g_network:connect_to(service_info._ip, service_info._port)
			Log.debug("ret=%s connect_index=%d", ret and "true" or "false", connect_index)
			if ret then
				service_info._connect_index = connect_index
				service_info._connect_status = ServiceConnectStatus.CONNECTING
				service_info._last_connect_time = now_time
			else
				Log.warn("******* connect to fail ip=%s port=%d", service_info._ip, service_info._port)
			end
			goto continue
		end

		-- connecting, check timeout
		Log.debug("connecting mailbox_id=%d connect_index=%d ip=%s port=%d", service_info._mailbox_id, service_info._connect_index, service_info._ip, service_info._port)
		if now_time - service_info._last_connect_time > 5 then
			-- connect time too long, close this connect
			Log.warn("!!!!!!! connecting timeout mailbox_id=%d ip=%s port=%d", service_info._mailbox_id, service_info._ip, service_info._port)
			if service_info._mailbox_id == 0 then
				-- not recv ConnectToRet event, something go wrong
				Log.err("!!!!!!! connecting timeout and not recv connect to ret event ip=%s port=%d", service_info._ip, service_info._port)
				goto continue
			end
			g_network:close_mailbox(service_info._mailbox_id) -- will cause luaworld:HandleDisconnect
			service_info._mailbox_id = 0 
			service_info._connect_status = ServiceConnectStatus.DISCONNECT
		end
		::continue::
	end
	if is_all_connected then
		Log.debug("******* all connect *******")
		if self._connect_timer_index ~= 0 then
			g_timer:del_timer(self._connect_timer_index)
			self._connect_timer_index = 0
		end
	end
end

function ServiceClient:connect_immediately()
	if self._connect_timer_index ~= 0 then
		return
	end
	-- do a connect now
	self:_connect_core()

	-- add timer for connect fail
	local function timer_cb()
		self:_connect_core()
	end
	self._connect_timer_index = g_timer:add_timer(self._connect_interval_ms, timer_cb, 0, true)
end

function ServiceClient:create_connect_timer()
	if self._connect_timer_index ~= 0 then
		return
	end

	local function timer_cb()
		self:_connect_core()
	end
	self._connect_timer_index = g_timer:add_timer(self._connect_interval_ms, timer_cb, 0, true)
end

--------------------------------------------------

function ServiceClient:get_service(mailbox_id)
	for _, service_info in ipairs(self._service_server_info_list) do
		if service_info._mailbox_id == mailbox_id then
			return service_info
		end
	end
	return nil
end

function ServiceClient:add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	local server_info = self._all_server_map[server_id]
	if server_info then
		Log.err("ServiceClient:add_server duplicate server_id=%d", server_id)
		return nil
	end

	-- init server_info
	local ServerInfo = require "core.service.server_info"
	server_info = ServerInfo.new(server_id, server_type, mailbox_id, single_scene_list, from_to_scene_list)
	-- Log.debug("server_info._scene_list=%s", Util.table_to_string(server_info._scene_list))

	-- add into all_server_map
	self._all_server_map[server_info._server_id] = server_info
	
	-- add into type_server_map
	self._type_server_map[server_type] = self._type_server_map[server_type] or {}
	table.insert(self._type_server_map[server_type], server_id)

	-- add into scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		self._scene_server_map[scene_id] = self._scene_server_map[scene_id] or {}
		table.insert(self._scene_server_map[scene_id], server_id)
	end

	Log.info("ServiceClient:add_server:")
	self:print()

	return server_info
end

function ServiceClient:connect_to_ret(connect_index, mailbox_id)
	-- just set service mailbox
	for _, service_info in ipairs(self._service_server_info_list) do
		if service_info._connect_index == connect_index then
			service_info._mailbox_id = mailbox_id
			service_info._connect_index = 0 -- bzero
			break
		end
	end
end

function ServiceClient:connect_to_success(mailbox_id)
	local service_info = self:get_service(mailbox_id)
	if not service_info then
		Log.err("ServiceClient:connect_to_success service nil %d", mailbox_id)
		return
	end
	-- of course is trust
	Net.add_mailbox(mailbox_id, service_info._ip, service_info._port)

	service_info._connect_status = ServiceConnectStatus.CONNECTED

	if service_info._register == 1 then
		-- send shake hand
		local msg = 
		{
			server_id = g_server_conf._server_id,
			server_type = g_server_conf._server_type,
			single_scene_list = g_server_conf._single_scene_list,
			from_to_scene_list = g_server_conf._from_to_scene_list,
			ip = g_server_conf._ip,
			port = g_server_conf._port,
		}
		Net.send_msg(mailbox_id, MID.SHAKE_HAND_REQ, msg)
	else
		-- no register, add server by service
		-- only use by client
		Log.debug("ServiceClient:connect_to_success mailbox_id=%d server_id=%d server_type=%d", service_info._server_id, service_info._server_type)
		self:add_server(mailbox_id, service_info._server_id, service_info._server_type, {}, {})
		Log.info("ServiceClient:connect_to_success:")
		self:print()
	end
end

function ServiceClient:shake_hand_success(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)
	local service_info = self:get_service(mailbox_id)
	if not service_info then
		Log.err("ServiceClient:register_success service nil %d %d %d", server_id, server_type)
		return
	end

	service_info._server_id = server_id
	service_info._server_type = server_type

	-- add service as a server too
	self:add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	Log.info("ServiceClient:register_success:")
	self:print()
end

function ServiceClient:_remove_server_core(mailbox_id, server_id)

	-- 1. server_info remove service mailbox
	-- 2. remove from type_server_map
	-- 3. remove from scene_server_map

	-- 1. server_info remove service mailbox
	local server_info = self._all_server_map[server_id]
	if not server_info then
		Log.err("ServiceClient:_remove_server_core server nil server_id=%d", server_id)
		return
	end

	-- 2. remove from type_server_map
	-- no more service connect to this server
	-- remove this server in type_server_map
	local type_server_list = self._type_server_map[server_info._server_type] or {}
	for i=#type_server_list, 1, -1 do
		if type_server_list[i] == server_id then
			table.remove(type_server_list, i)
		end
	end
	if #type_server_list == 0 then
		-- no more type server, clean up
		self._type_server_map[server_info._server_type] = nil
	end

	-- 3. remove from scene_server_map
	-- remove this server in scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		local scene_server_list = self._scene_server_map[scene_id]
		for i=#scene_server_list, 1, -1 do
			if scene_server_list[i] == server_id then
				table.remove(scene_server_list, i)
			end
		end
		if #scene_server_list == 0 then
			-- no more scene server, clean up
			self._scene_server_map[scene_id] = nil
		end
	end

	-- remove this server in all_server_map
	self._all_server_map[server_id] = nil
end

function ServiceClient:remove_server(mailbox_id, server_id)


	local service_info = self:get_service(mailbox_id)
	if not service_info then
		Log.err("ServiceClient:remove_server service nil mailbox_id=%d", mailbox_id)
		return
	end

	self._remove_server_core(mailbox_id, server_id)

	Log.info("ServiceClient:remove_server:")
	self:print()
end

function ServiceClient:handle_disconnect(mailbox_id)
	Log.info("ServiceClient:handle_disconnect mailbox_id=%d", mailbox_id)

	local service_info = self:get_service(mailbox_id)
	if not service_info then
		Log.err("ServiceClient:handle_disconnect service nil mailbox_id=%d", mailbox_id)
		return
	end

	self._remove_server_core(mailbox_id, service_info._server_id)

	if service_info._no_reconnect == 1 then
		Log.info("ServiceClient:handle_disconnect remove closing service %d", mailbox_id)
		-- mailbox is going to close, will not do reconnect
		-- remove from _service_server_info_list
		for k, service_info in ipairs(self._service_server_info_list) do
			if service_info._mailbox_id == mailbox_id then
				table.remove(self._service_server_info_list, k)
				break
			end
		end
		Log.info("ServiceClient:handle_disconnect:")
		self:print()
		return
	end

	-- set disconnect
	service_info._mailbox_id = -1
	service_info._connect_status = ServiceConnectStatus.DISCONNECT

	-- create connect timer to reconnect
	self:create_connect_timer()

	Log.info("ServiceClient:handle_disconnect:")
	self:print()
end

function ServiceClient:close_service(mailbox_id)
	local service_info = self:get_service(mailbox_id)
	if not service_info then
		Log.err("ServiceClient:close_service service nil mailbox_id=%d", mailbox_id)
		return
	end

	-- mark down, will clean up by handle_disconnect
	service_info._no_reconnect = 1

	-- core logic
	g_network:close_mailbox(mailbox_id)

end

function ServiceClient:close_service_by_type(server_type)

	local service_info = nil
	for _, sinfo in ipairs(self._service_server_info_list) do
		if sinfo._server_type == server_type then
			service_info = sinfo
			break
		end
	end

	if not service_info then
		Log.warn("ServiceClient:close_service_by_type no such service %d", server_type)
		return
	end

	self:close_service(service_info._mailbox_id)
end

----------------------------------------------

function ServiceClient:get_server_by_id(server_id)
	return self._all_server_map[server_id]
end

function ServiceClient:get_server_by_scene(scene_id)
	
	local id_list = {}
	local id_list = self._scene_server_map[scene_id] or {}
	if #id_list == 0 then
		return nil
	end

	local r = math.random(#id_list)
	local server_id = id_list[r]

	return self:get_server_by_id(server_id)
end

function ServiceClient:get_server_by_mailbox(mailbox_id)
	for server_id, server_info in pairs(self._all_server_map) do
		if server_info._mailbox_id == mailbox_id then
			return server_info
		end
	end

	return nil
end

-- same opt_key(number) will get same server, or just do random to get
function ServiceClient:get_server_by_type(server_type, opt_key)
	
	local id_list = {}
	local id_list = self._type_server_map[server_type] or {}
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

	return self:get_server_by_id(server_id)
end

-- luaclient use this now
function ServiceClient:send_to_type_server(server_type, msg_id, msg)
	local server_info = self:get_server_by_type(server_type)
	if not server_info then
		return false
	end

    return server_info:send_msg(msg_id, msg)
end

function ServiceClient:print()
	Log.info("************* ServiceClient ***********")
	Log.info("_service_server_info_list=")
	for k, service_info in ipairs(self._service_server_info_list) do
		service_info:print()
	end
	Log.info("_all_server_map=")
	for k, server_info in pairs(self._all_server_map) do
		server_info:print()
	end
	Log.info("_type_server_map=%s", Util.table_to_string(self._type_server_map))
	Log.info("_scene_server_map=%s", Util.table_to_string(self._scene_server_map))
	Log.info("***************************************")
end

return ServiceClient
