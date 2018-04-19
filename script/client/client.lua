
local Client = class()

function Client:ctor()
	-- assert only connect one login and one gate
	self._server_list = {} -- {[server_type]={ip=ip, port=port, server_id=server_id},}

	self._gate_ip = ""
	self._gate_port = 0

	self._user_id = 0
	self._user_token = ""

	self._area_role_list = {}
end


function Client:send_to_login(msg_id, msg)
	g_service_mgr:send_by_server_type(ServerType.LOGIN, msg_id, msg)
end

function Client:send_to_gate(msg_id, msg)
	g_service_mgr:send_by_server_type(ServerType.GATE, msg_id, msg)
end

return Client
