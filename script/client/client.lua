
local Client = class()

function Client:ctor()
	-- assert only connect one login and one gate
	self._server_list = {} -- {[server_type]={ip=ip, port=port, server_id=server_id},}

	self._gate_ip = ""
	self._gate_port = 0

	self._user_id = 0
	self._user_token = ""

	self._area_role_list = {}


	self.g_x_test_num = -1 -- x test end
	self.g_x_test_total_num = 0
	self.g_x_test_start_time = 0
	self.g_x_test_total_time = 0
	self.g_x_test_min_time = 0
end


function Client:send_to_login(msg_id, msg)
	g_service_mgr:send_by_server_type(ServerType.LOGIN, msg_id, msg)
end

function Client:send_to_gate(msg_id, msg)
	g_service_mgr:send_by_server_type(ServerType.GATE, msg_id, msg)
end

function Client:x_test_start(num)
	self.g_x_test_num = num
	self.g_x_test_total_num = num
	self.g_x_test_start_time = get_time_ms_c()
	self.g_x_test_total_time = 0
	self.g_x_test_min_time = 0
end

function Client:x_test_end()
	local time_ms = get_time_ms_c()
	if self.g_x_test_num > 0 then
		self.g_x_test_num = self.g_x_test_num - 1
		local time_ms_offset = time_ms - self.g_x_test_start_time
		self.g_x_test_total_time = self.g_x_test_total_time + time_ms_offset
		if self.g_x_test_min_time == 0 then
			self.g_x_test_min_time = time_ms_offset
		end
	end
	if self.g_x_test_num == 0 then
		Log.debug("******* x test time use time=%fms", time_ms - self.g_x_test_start_time)
		Log.debug("******* g_x_test_total_num=%d", self.g_x_test_total_num)
		Log.debug("******* g_x_test_total_time=%fms", self.g_x_test_total_time)
		Log.debug("******* average time=%fms", self.g_x_test_total_time/ self.g_x_test_total_num)
		Log.debug("******* min time=%fms", self.g_x_test_min_time)
		self.g_x_test_num = -1  -- x test end
	end
end

return Client
