
local Core = require "core"
local Log = require "log.logger"
local class = require "util.class"
local ServerInfo = class()

function ServerInfo:ctor(ip, port, no_shakehand, no_reconnect, mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)

	-- connection info
	self._ip = ip 
	self._port = port 
	self._no_shakehand = no_shakehand -- send my scene info to target server
	self._no_reconnect = no_reconnect -- default do reconnect
	self._connect_status = ServiceConnectStatus.DISCONNECT
	self._last_connect_time = 0

	self._mailbox_id = mailbox_id
	self._server_id = server_id
	self._server_type = server_type

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

function ServerInfo:set_scene(single_scene_list, from_to_scene_list)
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

function ServerInfo:set_mailbox_id(mailbox_id)
	self._mailbox_id = mailbox_id
end

-- get a mailbox to send msg
function ServerInfo:get_mailbox_id()
	return self._mailbox_id
end

function ServerInfo:set_no_reconnect(flag)
	self._no_reconnect = flag
end

function ServerInfo:send_msg(msg_id, msg)
	return self:send_msg_ext(msg_id, 0, msg)
end

function ServerInfo:send_msg_ext(msg_id, ext, msg)
	local mailbox_id = self:get_mailbox_id()
	if mailbox_id == MAILBOX_ID_NIL then
		Log.warn("ServerInfo:send_msg mailbox nil msg_id=%d", msg_id)
		return false
	end

	if self._connect_status ~= ServiceConnectStatus.CONNECTED then
		Log.warn("ServerInfo:send_msg not connected msg_id=%d", msg_id)
		return false
	end
	return Core.net_mgr:send_msg_ext(mailbox_id, msg_id, ext, msg)
end

function ServerInfo:transfer_msg(ext)
	local mailbox_id = self:get_mailbox_id()
	if mailbox_id == MAILBOX_ID_NIL then
		Log.err("ServerInfo:send_msg mailbox nil msg_id")
		return false
	end
	return Core.net_mgr:transfer_msg(mailbox_id, ext)
end

function ServerInfo:connect()
	self._last_connect_time = os.time()
	self._connect_status = ServiceConnectStatus.CONNECTING
	Core.timer_mgr:fork(function()
		local mailbox_id = Core.net_mgr:connect(self._ip, self._port)
		if mailbox_id ~= MAILBOX_ID_NIL then
			if self._connect_status == ServiceConnectStatus.DISCONNECTING then
				Core.net_mgr:close_mailbox(mailbox_id)
				return
			end
			self._mailbox_id = mailbox_id
			self._connect_status = ServiceConnectStatus.CONNECTED
			Core.net_mgr:add_mailbox(mailbox_id, self._ip, self._port)
			Core.server_mgr:on_connect_success(self)
		else
			self._connect_status = ServiceConnectStatus.DISCONNECT
			Core.server_mgr:on_connect_fail(self)
		end
	end)
end

function ServerInfo:print()
	Log.info("ServerInfo:print\nip=%s port=%d connect_status=%d\n_mailbox_id=%d _server_id=%d _server_type=[%d:%s]\n_single_scene_list=[%s] _from_to_scene_list=[%s]\n"
	, self._ip, self._port, self._connect_status
	, self._mailbox_id, self._server_id, self._server_type, ServerTypeName[self._server_type]
	, table.concat(self._single_scene_list, ",")
	, table.concat(self._from_to_scene_list, ","))
end

return ServerInfo

