
ServiceClient = class()

function ServiceClient:ctor()

	-- all connection
	-- {conn_info, conn_info, ...}
	self._server_connection_list = {} 

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

function ServiceClient:is_server(mailbox_id)
	for server_id, server_info in pairs(self._all_server_map) do
		if server_info._mailbox_id == mailbox_id then
			return true
		end
	end
	return false
end

function ServiceClient:do_connect(ip, port, server_id, server_type, no_shakehand, no_reconnect, no_delay)
	-- check duplicate connect service
	
	no_shakehand = no_shakehand or 0
	no_reconnect = no_reconnect or 0
	no_delay = no_delay or 0

	for k, v in ipairs(self._server_connection_list) do
		if v._ip == ip and v.port == port then
			Log.warn("ServiceClient:do_connect duplicate add ip=%s port=%d", ip, port)
			return
		end
	end
	
	local ServerConnectionInfo = require "core.service.server_connection_info"
	local conn_info = ServerConnectionInfo.new(ip, port, server_id, server_type, no_shakehand, no_reconnect)
	table.insert(self._server_connection_list, conn_info)
	if no_delay == 1 then
		self:connect_immediately()
	else
		self:create_connect_timer()
	end
end

function ServiceClient:_connect_core()

	Log.debug("ServiceClient:_connect_core")
	-- Log.debug("handle_client_test: self._server_connection_list=%s", Util.table_to_string(self._server_connection_list))
	local now_time = os.time()
	
	local is_all_connected = true
	for _, conn_info in ipairs(self._server_connection_list) do
		Log.debug("ServiceClient:_connect_core conn_info ip=%s port=%d connect_status=%d", conn_info._ip, conn_info._port, conn_info._connect_status)
		if conn_info._connect_status == ServiceConnectStatus.CONNECTED then
			goto continue
		end

		is_all_connected = false
		-- not connecting, do connect
		if conn_info._connect_status == ServiceConnectStatus.DISCONNECT then
			Log.debug("connect to ip=%s port=%d", conn_info._ip, conn_info._port)
			-- only return a connect_index, get mailbox_id later
			local ret, connect_index = g_network:connect_to(conn_info._ip, conn_info._port)
			Log.debug("ret=%s connect_index=%d", ret and "true" or "false", connect_index)
			if ret then
				conn_info._connect_index = connect_index
				conn_info._connect_status = ServiceConnectStatus.CONNECTING
				conn_info._last_connect_time = now_time
			else
				Log.warn("******* connect to fail ip=%s port=%d", conn_info._ip, conn_info._port)
			end
			goto continue
		end

		-- connecting, check timeout
		Log.debug("connecting mailbox_id=%d connect_index=%d ip=%s port=%d", conn_info._mailbox_id, conn_info._connect_index, conn_info._ip, conn_info._port)
		if now_time - conn_info._last_connect_time > 5 then
			-- connect time too long, close this connect
			Log.warn("!!!!!!! connecting timeout mailbox_id=%d ip=%s port=%d", conn_info._mailbox_id, conn_info._ip, conn_info._port)
			if conn_info._mailbox_id == 0 then
				-- not recv ConnectToRet event, something go wrong
				Log.err("!!!!!!! connecting timeout and not recv connect to ret event ip=%s port=%d", conn_info._ip, conn_info._port)
				goto continue
			end
			g_network:close_mailbox(conn_info._mailbox_id) -- will cause luaworld:HandleDisconnect
			conn_info._mailbox_id = 0 
			conn_info._connect_status = ServiceConnectStatus.DISCONNECT
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

function ServiceClient:get_conn_info(mailbox_id)
	for _, conn_info in ipairs(self._server_connection_list) do
		if conn_info._mailbox_id == mailbox_id then
			return conn_info
		end
	end
	return nil
end

--------------------------------------------------

function ServiceClient:add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	local server_info = self._all_server_map[server_id]
	if server_info then
		-- if exists in all_server_map, duplicate add
		Log.err("ServiceClient:add_server duplicate add mailbox_id=%d server_id=%d", mailbox_id, server_id)
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

	return server_info
end

function ServiceClient:connect_to_ret(connect_index, mailbox_id)
	-- just set service mailbox
	for _, conn_info in ipairs(self._server_connection_list) do
		if conn_info._connect_index == connect_index then
			conn_info._mailbox_id = mailbox_id
			conn_info._connect_index = 0 -- bzero
			break
		end
	end
end

function ServiceClient:connect_to_success(mailbox_id)
	local conn_info = self:get_conn_info(mailbox_id)
	if not conn_info then
		Log.err("ServiceClient:connect_to_success service nil %d", mailbox_id)
		return
	end
	-- of course is trust
	Net.add_mailbox(mailbox_id, conn_info._ip, conn_info._port)

	conn_info._connect_status = ServiceConnectStatus.CONNECTED

	if conn_info._no_shakehand == 0 then
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
		-- no_shakehand, add server by service
		-- only use by client
		Log.debug("ServiceClient:connect_to_success mailbox_id=%d server_id=%d server_type=%d", conn_info._server_id, conn_info._server_type)
		self:add_server(mailbox_id, conn_info._server_id, conn_info._server_type, {}, {})
		Log.info("ServiceClient:connect_to_success:")
		self:print()
	end
end

function ServiceClient:shake_hand_success(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)
	local conn_info = self:get_conn_info(mailbox_id)
	if not conn_info then
		Log.err("ServiceClient:shake_hand_success service nil %d %d %d", server_id, server_type)
		return
	end

	conn_info._server_id = server_id
	conn_info._server_type = server_type

	-- add service as a server too
	self:add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	Log.info("ServiceClient:shake_hand_success:")
	self:print()
end

function ServiceClient:remove_server(server_info)

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

function ServiceClient:handle_disconnect(mailbox_id)
	Log.info("ServiceClient:handle_disconnect mailbox_id=%d", mailbox_id)

	local conn_info = self:get_conn_info(mailbox_id)
	if not conn_info then
		Log.err("ServiceClient:handle_disconnect service nil mailbox_id=%d", mailbox_id)
		return
	end

	local server_info = self:get_server_by_mailbox(mailbox_id)
	if not server_info then
		Log.err("ServiceClient:_remove_server_core server nil server_id=%d", server_id)
		return
	end

	self:remove_server(server_info)

	if conn_info._no_reconnect == 1 then
		Log.info("ServiceClient:handle_disconnect remove closing service %d", mailbox_id)
		-- mailbox is going to close, will not do reconnect
		-- remove from _server_connection_list
		for k, conn_info in ipairs(self._server_connection_list) do
			if conn_info._mailbox_id == mailbox_id then
				table.remove(self._server_connection_list, k)
				break
			end
		end
		Log.info("ServiceClient:handle_disconnect:")
		self:print()
		return
	end

	-- set disconnect
	conn_info._mailbox_id = -1
	conn_info._connect_status = ServiceConnectStatus.DISCONNECT

	-- create connect timer to reconnect
	self:create_connect_timer()

	Log.info("ServiceClient:handle_disconnect:")
	self:print()
end

function ServiceClient:close_connection(mailbox_id)
	local conn_info = self:get_conn_info(mailbox_id)
	if not conn_info then
		Log.err("ServiceClient:close_connection conn_info nil mailbox_id=%d", mailbox_id)
		return
	end

	-- mark down, will clean up by handle_disconnect
	conn_info._no_reconnect = 1

	-- core logic
	g_network:close_mailbox(mailbox_id)

end

function ServiceClient:close_connection_by_type(server_type)

	local conn_info = nil
	for _, cinfo in ipairs(self._server_connection_list) do
		if cinfo._server_type == server_type then
			conn_info = cinfo
			break
		end
	end

	if not conn_info then
		Log.warn("ServiceClient:close_connection_by_type no such type %d", server_type)
		return
	end

	self:close_connection(conn_info._mailbox_id)
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
	Log.info("\n******* ServiceClient *******")
	Log.info("_server_connection_list=")
	for k, conn_info in ipairs(self._server_connection_list) do
		conn_info:print()
	end
	Log.info("_all_server_map=")
	for k, server_info in pairs(self._all_server_map) do
		server_info:print()
	end
	Log.info("_type_server_map=%s", Util.table_to_string(self._type_server_map))
	Log.info("_scene_server_map=%s", Util.table_to_string(self._scene_server_map))
	Log.info("*******\n")
end

return ServiceClient
