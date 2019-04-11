
local server_conf = require "global.server_conf"
local Log = require "log.logger"
local Util = require "util.util"
local class = require "util.class"
local ServerInfo = require "server.server_info"
local cerberus = require "cerberus"
local msg_def = require "global.net_msg_def"
local MID = msg_def.MID

local ServerMgr = {
	-- store not connected or not shake hand server
	-- {server_info, server_info, ...}
	_wait_server_list = {},

	-- store active server map
	-- {server_id = server_info, ...}
	_active_server_map = {},

	-- {server_type = {server_id, server_id, ...}
	_type_server_map = {},

	-- {scene_id = {server_id, server_id, ...}
	_scene_server_map = {},
}

function ServerMgr:get_server_by_id(server_id)
	return self._active_server_map[server_id]
end

function ServerMgr:get_server_by_host(ip, port)
	for k, v in pairs(self._active_server_map) do
		if v._ip == ip and v._port == port then
			return v
		end
	end
	for k, v in ipairs(self._wait_server_list) do
		if v._ip == ip and v._port == port then
			return v
		end
	end
	return nil
end

function ServerMgr:get_server_by_mailbox(mailbox_id)
	for _, server_info in pairs(self._active_server_map) do
		if server_info._mailbox_id == mailbox_id then
			return server_info
		end
	end
	return nil
end

function ServerMgr:get_server_by_scene(scene_id)
	
	local id_list = self._scene_server_map[scene_id] or {}
	if #id_list == 0 then
		return nil
	end

	local r = math.random(#id_list)
	local server_id = id_list[r]

	return self:get_server_by_id(server_id)
end

-- same opt_key(number) will get same server, or just do random to get
function ServerMgr:get_server_by_type(server_type, opt_key)
	
	local id_list = self._type_server_map[server_type] or {}
	if #id_list == 0 then
		return nil
	end

	local server_id
	if not opt_key then
		local r = math.random(#id_list)
		server_id = id_list[r]
	else
		local r = opt_key % #id_list + 1
		server_id = id_list[r]
	end

	return self:get_server_by_id(server_id)
end

-------------------------------------------------

function ServerMgr:create_mesh()
	local server_conf = server_conf
	local ip = server_conf._ip
	local port = server_conf._port
	if ip ~= "" and port ~= 0 then
		Log.debug("ServerMgr:create_mesh listen ip=%s port=%d", ip, port)
		local listen_id = cerberus:listen(ip, port)
		Log.info("ServerMgr:create_mesh listen_id=%d", listen_id)
		if listen_id < 0 then
			Log.err("ServerMgr:create_mesh listen fail ip=%s port=%d", ip, port)
			return false
		end
	end
	
	for _, v in ipairs(server_conf._connect_to) do
		Log.debug("ServerMgr:create_mesh connect ip=%s port=%d", v.ip, v.port)
		self:do_connect(v.ip, v.port)
	end
	return true
end

function ServerMgr:do_connect(ip, port, server_id, server_type, no_shakehand, no_reconnect)

	server_id = server_id or 0
	server_type = server_type or 0
	
	-- check duplicate connect server
	local server_info = self:get_server_by_host(ip, port)
	if server_info then
		Log.warn("ServerMgr:do_connect host exists ip=%s port=%d", ip, port)
		return
	end
	
	server_info = ServerInfo.new(ip, port, no_shakehand, no_reconnect, MAILBOX_ID_NIL, server_id, server_type, {}, {})
	table.insert(self._wait_server_list, server_info)
	server_info:connect()
end

function ServerMgr:do_reconnect(server_info)
	table.insert(self._wait_server_list, server_info)
	server_info:connect()
end

--------------------------------------------------

-- register a connect to server
function ServerMgr:register_server(server_info)

	Log.debug("ServerMgr:register_server mailbox_id=%d server_id=%d server_type=%d"
	, server_info._mailbox_id, server_info._server_id, server_info._server_type)

	local mailbox_id = server_info._mailbox_id
	local server_id = server_info._server_id
	local server_type = server_info._server_type

	if self._active_server_map[server_id] then
		-- if exists in all_server_map, duplicate add
		Log.err("ServerMgr:register_server duplicate add mailbox_id=%d server_id=%d", mailbox_id, server_id)
		return false
	end

	-- add into all_server_map
	self._active_server_map[server_id] = server_info
	
	-- add into type_server_map
	self._type_server_map[server_type] = self._type_server_map[server_type] or {}
	table.insert(self._type_server_map[server_type], server_id)
	table.sort(self._type_server_map[server_type])

	-- add into scene_server_map
	for _, scene_id in ipairs(server_info._scene_list) do
		self._scene_server_map[scene_id] = self._scene_server_map[scene_id] or {}
		table.insert(self._scene_server_map[scene_id], server_id)
	end

	return true
end

function ServerMgr:unregister_server(server_info)

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
	self._active_server_map[server_id] = nil
end

-- add a connect in server
function ServerMgr:add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	Log.debug("ServerMgr:add_server mailbox_id=%d server_id=%d server_type=%d"
	, mailbox_id, server_id, server_type)

	local server_info = self._active_server_map[server_id]
	if server_info then
		-- if exists in all_server_map, duplicate add
		Log.err("ServerMgr:add_server duplicate add mailbox_id=%d server_id=%d", mailbox_id, server_id)
		return nil
	end

	-- init server_info, port is 0
	server_info = ServerInfo.new("", 0, false, false, mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)
	server_info._connect_status = ServiceConnectStatus.CONNECTED

	self:register_server(server_info)

	Log.debug("ServerMgr:add_server")
	self:print()
	return server_info
end

--------------------------------------------

function ServerMgr:on_connect_success(server_info)
	Log.info("ServerMgr:on_connect_success mailbox_id=%d", server_info._mailbox_id)
	local index_in_list
	for k, v in ipairs(self._wait_server_list) do
		if v == server_info then
			index_in_list = k
			break
		end
	end
	assert(index_in_list, "ServerMgr:connect_to_success server")

	if server_info._no_shakehand then
		-- no_shakehand, local register server
		-- now use by client
		Log.debug("ServerMgr:connect_to_success mailbox_id=%d server_id=%d server_type=%d", server_info._mailbox_id, server_info._server_id, server_info._server_type)
		self:register_server(server_info)
		-- remove from connection list
		table.remove(self._wait_server_list, index_in_list)
		return
	end

	-- send shake hand
	local msg =
	{
		server_id = server_conf._server_id,
		server_type = server_conf._server_type,
		single_scene_list = server_conf._single_scene_list,
		from_to_scene_list = server_conf._from_to_scene_list,
		ip = server_conf._ip,
		port = server_conf._port,
	}
	server_info:send_msg(MID.s2s_shake_hand_req, msg)
end

function ServerMgr:_on_connection_down(server_info)

	if server_info._no_reconnect or server_info._port == 0 then
		-- no reconnect or connect in, do nothing
		Log.warn("ServerMgr:_on_connection_down no need reconnect [%d:%s]", server_info._server_type, ServerTypeName[server_info._server_type])
		return
	end

	self:do_reconnect(server_info)
end

function ServerMgr:on_connect_fail(server_info)
	Log.info("ServerMgr:on_connect_fail mailbox_id=%d", server_info._mailbox_id)

	for k, v in ipairs(self._wait_server_list) do
		if v == server_info then
			table.remove(self._wait_server_list, k)
			break
		end
	end

	self:_on_connection_down(server_info)
end

function ServerMgr:on_connection_close(server_info)

	local found = false
	repeat
		for k, v in ipairs(self._wait_server_list) do
			if v == server_info then
				-- remove from wait connect list
				table.remove(self._wait_server_list, k)
				found = true
				break
			end
		end
		if found then break end
		for _, v in pairs(self._active_server_map) do
			if v._mailbox_id == server_info._mailbox_id then
				self:unregister_server(server_info)
				found = true
				break
			end
		end
	until true

	if not found then
		Log.warn("ServerMgr:on_connection_close server nil mailbox_id=%d", server_info._mailbox_id)
		return
	end

	self:_on_connection_down(server_info)
end

function ServerMgr:shake_hand_success(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

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
		Log.err("ServerMgr:shake_hand_success server nil mailbox_id=%d _wait_server_list=%s", mailbox_id, Util.table_to_string(self._wait_server_list))
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

function ServerMgr:close_connection(server_info, no_reconnect)
	server_info._no_reconnect = no_reconnect
	server_info._connect_status = ServiceConnectStatus.DISCONNECTING
	if server_info._mailbox_id ~= MAILBOX_ID_NIL then
		local net_mgr = require "net.net_mgr"
		net_mgr:close_mailbox(server_info._mailbox_id)
	end
end

function ServerMgr:close_connection_by_type(server_type, no_reconnect)

	local server_info = nil
	for k, v in pairs(self._active_server_map) do
		if v._server_type == server_type then
			server_info = v
			break
		end
	end

	if not server_info then
		Log.warn("ServerMgr:close_connection_by_type no such type %d", server_type)
		return
	end
	self:close_connection(server_info, no_reconnect)
end

function ServerMgr:close_connection_by_host(ip, port, no_reconnect)
	local server_info = self:get_server_by_host(ip, port)
	if not server_info then
		Log.warn("ServerMgr:close_connection_by_host no such host %s:%d", ip, port)
		return
	end
	self:close_connection(server_info, no_reconnect)
end

----------------------------------------------

function ServerMgr:send_by_server_type(server_type, msg_id, data, opt_key)
	local server_info = self:get_server_by_type(server_type, opt_key)
	if not server_info then
		Log.err("ServerMgr:send_server_by_type nil %s %d", server_type, opt_key or 0)
		return false
	end

	return server_info:send_msg(msg_id, data)
end


function ServerMgr:print()
	Log.debug("\n******* ServerMgr *******")
	Log.debug("_wait_server_list=")
	for k, server_info in ipairs(self._wait_server_list) do
		server_info:print()
	end
	Log.debug("_active_server_map=")
	for k, server_info in pairs(self._active_server_map) do
		server_info:print()
	end
	Log.info("_type_server_map=%s", Util.table_to_string(self._type_server_map))
	Log.info("_scene_server_map=%s", Util.table_to_string(self._scene_server_map))
	Log.info("*******\n")
end

return ServerMgr
