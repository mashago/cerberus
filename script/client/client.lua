
local Client = class()

function Client:ctor()
	-- assert only connect one login and one router
	self._server_list = {} -- {[server_type]={ip=ip, port=port, server_id=server_id},}

	self._router_ip = ""
	self._router_port = 0

	self._user_id = 0
	self._user_token = ""
end

return Client
