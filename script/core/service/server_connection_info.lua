
local ServerConnectionInfo = class()

function ServerConnectionInfo:ctor(ip, port, server_id, server_type, no_shakehand, no_reconnect)
	self._ip = ip 
	self._port = port 
	self._server_id = server_id or 0 
	self._server_type = server_type or 0 

	self._no_shakehand = no_shakehand -- 0 or 1 send my scene info to target service
	self._no_reconnect = no_reconnect -- 0 or 1 default do reconnect

	self._mailbox_id = 0
	self._connect_index = 0
	self._connect_status = ServiceConnectStatus.DISCONNECT
	self._last_connect_time = 0

end

function ServerConnectionInfo:print()
	Log.info("ServerConnectionInfo:print ip=%s port=%d server_id=%d server_type=%d no_shakehand=%d no_reconnect=%d mailbox_id=%d connect_index=%d connect_status=%d last_connect_time=%d"
	, self._ip, self._port, self._server_id, self._server_type
	, self._no_shakehand, self._no_reconnect
	, self._mailbox_id, self._connect_index, self._connect_status, self._last_connect_time)
end

return ServerConnectionInfo
