
local Client = class()

function Client:ctor()
	-- assert only connect one login and one gate
	self._server_list = {} -- {[server_type]={ip=ip, port=port, server_id=server_id},}

	self._gate_ip = ""
	self._gate_port = 0

	self._user_id = 0
	self._user_token = ""
end

return Client
