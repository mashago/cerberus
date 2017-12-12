
local ServiceServerInfo = class()

function ServiceServerInfo:ctor(ip, port, server_id, server_type, register, invite, no_reconnect)
	self._ip = ip 
	self._port = port 
	self._server_id = server_id or 0 
	self._server_type = server_type or 0 

	self._register = register -- 0 or 1 send my scene info to target service
	self._invite = invite -- 0 or 1 invite target service connect me
	self._no_reconnect = no_reconnect -- 0 or 1 default do reconnect

	self._mailbox_id = 0
	self._connect_index = 0

	self._is_connecting = false
	self._is_connected = false
	self._last_connect_time = 0
	self._server_list = {} -- {server_id1 server_id2}
end

return ServiceServerInfo
