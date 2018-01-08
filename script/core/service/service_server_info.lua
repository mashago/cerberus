
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
	self._connect_status = ServiceConnectStatus.DISCONNECT
	self._last_connect_time = 0

end

function ServiceServerInfo:print()
	Log.info("------ServiceServerInfo--------")
	Log.info("ip=%s port=%d server_id=%d server_type=%d", self._ip, self._port, self._server_id, self._server_type)
	Log.info("register=%d invite=%d no_reconnect=%d", self._register, self._invite, self._no_reconnect)
	Log.info("mailbox_id=%d connect_index=%d connect_status=%d last_connect_time=%d", self._mailbox_id, self._connect_index, self._connect_status, self._last_connect_time)
	Log.info("--------------")
end

return ServiceServerInfo
