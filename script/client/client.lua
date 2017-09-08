
local Client = {}

function Client:new()
	local obj = {}
	self.__index = self
	setmetatable(obj, self)

	-- assert only connect one login and one router
	obj._server_list = {} -- {[server_type]={ip=ip, port=port, server_id=server_id},}

	obj._router_ip = ""
	obj._router_port = 0

	obj._user_id = 0
	obj._user_token = ""

	return obj
end

return Client
