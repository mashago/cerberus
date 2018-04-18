
ServiceMgr = class()

function ServiceMgr:ctor()

	-- store not connected server
	-- {server_info, server_info, ...}
	self._wait_server_list = {} 

	-- store connected server map
	-- {server_id = server_info, ...}
	self._all_server_map = {}

	-- {server_type = {server_id, server_id, ...}
	self._type_server_map = {}

	-- {scene_id = {server_id, server_id, ...}
	self._scene_server_map = {}

	self._connect_timer_index = 0
	self._connect_interval_ms = 2000
end

function ServiceMgr:do_connect(ip, port, server_id, server_type, no_shakehand, no_reconnect, no_delay)
	
	-- check duplicate connect service
	for k, v in ipairs(self._wait_server_list) do
		if v._ip == ip and v._port == port then
			Log.warn("ServiceMgr:do_connect connecting ip=%s port=%d", ip, port)
			return
		end
	end

	for k, v in pairs(self._all_server_map) do
		if v._ip == ip and v._port == port then
			Log.warn("ServiceMgr:do_connect connected ip=%s port=%d", ip, port)
			return
		end
	end
	
	local ServerInfo = require "core.service.server_info"
	server_info = ServerInfo.new(ip, port, no_shakehand, no_reconnect, MAILBOX_ID_NIL, server_id, server_type, {}, {})
	table.insert(self._wait_server_list, server_info)

	if no_delay then
		self:connect_immediately()
	else
		self:create_connect_timer()
	end
end

function ServiceMgr:_connect_core()

	-- Log.debug("ServiceMgr:_connect_core: self._wait_server_list=%s", Util.table_to_string(self._wait_server_list))
	local now_time = os.time()
	
	local is_all_connected = true
	for _, server_info in ipairs(self._wait_server_list) do
		Log.debug("ServiceMgr:_connect_core server_info ip=%s port=%d connect_status=%d", server_info._ip, server_info._port, server_info._connect_status)
		if server_info._connect_status == ServiceConnectStatus.CONNECTED then
			goto continue
		end

		is_all_connected = false
		if server_info._connect_status == ServiceConnectStatus.DISCONNECT then
			-- not connecting, do connect
			-- only return a connect_index, get mailbox_id later
			local ret, connect_index = g_network:connect_to(server_info._ip, server_info._port)
			if ret then
				server_info._connect_index = connect_index
				server_info._connect_status = ServiceConnectStatus.CONNECTING
				server_info._last_connect_time = now_time
			else
				Log.err("******* connect to fail ip=%s port=%d", server_info._ip, server_info._port)
			end

		elseif server_info._connect_status == ServiceConnectStatus.CONNECTING then
			-- connecting, check timeout
			if now_time - server_info._last_connect_time < 5 then
				goto continue
			end

			-- connect time too long, close this connect
			Log.warn("!!!!!!! connecting timeout mailbox_id=%d ip=%s port=%d", server_info._mailbox_id, server_info._ip, server_info._port)
			if server_info._mailbox_id == MAILBOX_ID_NIL then
				-- TODO not recv ConnectToRet event, something go wrong
				Log.err("!!!!!!! connecting timeout and not recv connect to ret event ip=%s port=%d", server_info._ip, server_info._port)
				goto continue
			end
			-- will cause luaworld:HandleDisconnect
			self:close_connection(server_info, false)
		end

		::continue::
	end

	Log.debug("ServiceMgr:_connect_core")
	self:print()

	if is_all_connected then
		Log.debug("******* all connect *******")
		if self._connect_timer_index ~= 0 then
			g_timer:del_timer(self._connect_timer_index)
			self._connect_timer_index = 0
		end
	end
end

function ServiceMgr:connect_immediately()
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

function ServiceMgr:create_connect_timer()
	if self._connect_timer_index ~= 0 then
		return
	end

	local function timer_cb()
		self:_connect_core()
	end
	self._connect_timer_index = g_timer:add_timer(self._connect_interval_ms, timer_cb, 0, true)
end

--------------------------------------------------

-- register a connect to server
function ServiceMgr:register_server(server_info)

	Log.debug("ServiceMgr:register_server mailbox_id=%d server_id=%d server_type=%d"
	, server_info._mailbox_id, server_info._server_id, server_info._server_type)

	local mailbox_id = server_info._mailbox_id
	local server_id = server_info._server_id
	local server_type = server_info._server_type

	if self._all_server_map[server_id] then
		-- if exists in all_server_map, duplicate add
		Log.err("ServiceMgr:register_server duplicate add mailbox_id=%d server_id=%d", mailbox_id, server_id)
		return false
	end

	-- add into all_server_map
	self._all_server_map[server_id] = server_info
	
	-- add into type_server_map
	self._type_server_map[server_type] = self._type_server_map[server_type] or {}
	table.insert(self._type_server_map[server_type], server_id)

	-- add into scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		self._scene_server_map[scene_id] = self._scene_server_map[scene_id] or {}
		table.insert(self._scene_server_map[scene_id], server_id)
	end

	return true
end

-- add a connect in server
function ServiceMgr:add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	Log.debug("ServiceMgr:add_server mailbox_id=%d server_id=%d server_type=%d"
	, mailbox_id, server_id, server_type)

	local server_info = self._all_server_map[server_id]
	if server_info then
		-- if exists in all_server_map, duplicate add
		Log.err("ServiceMgr:add_server duplicate add mailbox_id=%d server_id=%d", mailbox_id, server_id)
		return nil
	end

	-- init server_info, port is 0
	local ServerInfo = require "core.service.server_info"
	server_info = ServerInfo.new("", 0, false, false, mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)
	server_info._connect_status = ServiceConnectStatus.CONNECTED

	self:register_server(server_info)

	Log.debug("ServiceMgr:add_server")
	self:print()
	return server_info
end

function ServiceMgr:unregister_server(server_info)

	local server_id = server_info._server_id

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

--------------------------------------------

function ServiceMgr:connect_to_ret(connect_index, mailbox_id)
	-- just set service mailbox
	local is_ok = false
	for _, server_info in ipairs(self._wait_server_list) do
		if server_info._connect_index == connect_index then
			server_info._mailbox_id = mailbox_id
			server_info._connect_index = 0 -- bzero
			is_ok = true
			break
		end
	end
	if not is_ok then
		Log.err("ServiceMgr:connect_to_ret server nil connect_index=%d mailbox_id=%d", connect_index, mailbox_id)
	end
end

function ServiceMgr:connect_to_success(mailbox_id)
	
	local index_in_list = 0
	local server_info = nil
	for k, v in ipairs(self._wait_server_list) do
		if v._mailbox_id == mailbox_id then
			index_in_list = k
			server_info = v
			break
		end
	end
	if not server_info then
		Log.err("ServiceMgr:connect_to_success service nil %d", mailbox_id)
		return
	end

	if server_info._connect_status == ServiceConnectStatus.DISCONNECTING then
		Log.warn("ServiceMgr:connect_to_success already disconnecting server_id=%d mailbox_id=%d", server_info._server_id, mailbox_id)
		return
	end

	Net.add_mailbox(mailbox_id, server_info._ip, server_info._port)

	server_info._connect_status = ServiceConnectStatus.CONNECTED

	if server_info._no_shakehand then
		-- no_shakehand, local register server
		-- only use by client
		Log.debug("ServiceMgr:connect_to_success mailbox_id=%d server_id=%d server_type=%d", mailbox_id, server_info._server_id, server_info._server_type)
		self:register_server(server_info)
		-- remove from connection list
		table.remove(self._wait_server_list, index_in_list)
		return
	end

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
	Net.send_msg(mailbox_id, MID.s2s_shake_hand_req, msg)
end

function ServiceMgr:shake_hand_success(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	local index_in_list = 0
	local server_info = nil
	for k, v in ipairs(self._wait_server_list) do
		if v._mailbox_id == mailbox_id then
			index_in_list = k
			server_info = v
			break
		end
	end
	if not server_info then
		Log.err("ServiceMgr:shake_hand_success server nil mailbox_id=%d _wait_server_list=%s", mailbox_id, Util.table_to_string(self._wait_server_list))
		return
	end

	server_info._server_id = server_id
	server_info._server_type = server_type
	server_info:set_scene(single_scene_list, from_to_scene_list)
	if not self:register_server(server_info) then
		return false
	end
	table.remove(self._wait_server_list, index_in_list)

	return true
end

function ServiceMgr:handle_disconnect(mailbox_id)
	Log.info("ServiceMgr:handle_disconnect mailbox_id=%d", mailbox_id)

	local is_connected = false
	local server_info = nil
	repeat
		for k, v in ipairs(self._wait_server_list) do
			if v._mailbox_id == mailbox_id then
				server_info = v
				-- remove from wait connect list
				table.remove(self._wait_server_list, k)
				break
			end
		end
		if server_info then break end
		for _, v in pairs(self._all_server_map) do
			if v._mailbox_id == mailbox_id then
				server_info = v
				is_connected = true
				break
			end
		end
	until true

	if not server_info then
		Log.info("ServiceMgr:handle_disconnect server nil mailbox_id=%d", mailbox_id)
	end

	if is_connected then
		self:unregister_server(server_info)
	end

	if server_info._no_reconnect or server_info._port == 0 then
		-- no reconnect or connect in, do nothing
		Log.info("ServiceMgr:handle_disconnect")
		self:print()
		return
	end

	server_info._mailbox_id = MAILBOX_ID_NIL
	server_info._connect_status = ServiceConnectStatus.DISCONNECT

	-- create connect timer to reconnect
	table.insert(self._wait_server_list, server_info)
	self:create_connect_timer()

	Log.info("ServiceMgr:handle_disconnect")
	self:print()
end

function ServiceMgr:close_connection(server_info, no_reconnect)
	server_info._no_reconnect = no_reconnect
	server_info._connect_status = ServiceConnectStatus.DISCONNECTING
	g_network:close_mailbox(mailbox_id)
end

function ServiceMgr:close_connection_by_type(server_type, no_reconnect)

	local server_info = nil
	for k, v in pairs(self._all_server_map) do
		if v._server_type == server_type then
			server_info = v
			break
		end
	end

	if not server_info then
		Log.warn("ServiceMgr:close_connection_by_type no such type %d", server_type)
		return
	end
	self:close_connection(server_info, no_reconnect)
end

----------------------------------------------

function ServiceMgr:get_server_by_id(server_id)
	return self._all_server_map[server_id]
end

function ServiceMgr:get_server_by_mailbox(mailbox_id)
	for _, server_info in ipairs(self._wait_server_list) do
		if server_info._mailbox_id == mailbox_id then
			return server_info
		end
	end
	for _, server_info in pairs(self._all_server_map) do
		if server_info._mailbox_id == mailbox_id then
			return server_info
		end
	end
	return nil
end

function ServiceMgr:get_server_by_scene(scene_id)
	
	local id_list = {}
	local id_list = self._scene_server_map[scene_id] or {}
	if #id_list == 0 then
		return nil
	end

	local r = math.random(#id_list)
	local server_id = id_list[r]

	return self:get_server_by_id(server_id)
end

-- same opt_key(number) will get same server, or just do random to get
function ServiceMgr:get_server_by_type(server_type, opt_key)
	
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
function ServiceMgr:send_to_type_server(server_type, msg_id, msg)
	local server_info = self:get_server_by_type(server_type)
	if not server_info then
		return false
	end

    return server_info:send_msg(msg_id, msg)
end

function ServiceMgr:send_by_server_type(server_type, msg_id, data, opt_key)
	local server_info = self:get_server_by_type(server_type, opt_key)
	if not server_info then
		Log.err("ServiceMgr:send_server_by_type nil %s %d", server_type, opt_key)
		return false
	end

	return server_info:send_msg(msg_id, data)
end


function ServiceMgr:print()
	Log.info("\n******* ServiceMgr *******")
	Log.info("_wait_server_list=")
	for k, server_info in ipairs(self._wait_server_list) do
		server_info:print()
	end
	Log.info("_all_server_map=")
	for k, server_info in pairs(self._all_server_map) do
		server_info:print()
	end
	Log.info("_type_server_map=%s", Util.table_to_string(self._type_server_map))
	Log.info("_scene_server_map=%s", Util.table_to_string(self._scene_server_map))
	Log.info("*******\n")
end

return ServiceMgr
