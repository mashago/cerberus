
local Env = require "env"
local Log = require "core.log.logger"
local g_funcs = require "core.global.global_funcs"
local class = require "core.util.class"
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

function Client:load_server_list(xml_doc)
	-- init server list
	local root_ele = xml_doc:first_child_element()
	if not root_ele then
		Log.err("tinyxml root_ele nil %s", g_conf_file)
		return false
	end

	local server_list_ele = root_ele:first_child_element("server_list")
	if not server_list_ele then
		Log.err("tinyxml server_list_ele nil %s", g_conf_file)
		return false
	end

	local address_ele = server_list_ele:first_child_element("address")
	while address_ele do
		local ip = address_ele:string_attribute("ip")
		local port = address_ele:int_attribute("port")
		local server_id = address_ele:int_attribute("id")
		local server_type = address_ele:int_attribute("type")
		Log.info("ip=%s port=%d server_id=%d server_type=%d", ip, port, server_id, server_type)

		self._server_list[server_type] =
		{
			ip = ip,
			port = port,
			server_id = server_id,
		}

		address_ele = address_ele:next_sibling_element()
	end
end


function Client:send_to_login(msg_id, msg)
	Env.server_mgr:send_by_server_type(ServerType.LOGIN, msg_id, msg)
end

function Client:send_to_gate(msg_id, msg)
	Env.server_mgr:send_by_server_type(ServerType.GATE, msg_id, msg)
end

function Client:random_change_attr()
	local kvs =
	{
		pos_x = math.random(1, 2^15),
		pos_y = math.random(1, 2^15),
		cur_hp = math.random(1, 100),
	}

	local out_attr_table = g_funcs.get_empty_attr_table()
	local table_def = DataStructDef.data.role_info

	for attr_name, value in pairs(kvs) do
		local field_def = table_def[attr_name]
		if not field_def then
			break
		end
		value = g_funcs.str_to_value(value, field_def.type)
		if not value then
			break
		end
		g_funcs.set_attr_table(out_attr_table, table_def, attr_name, value)
	end

	local msg =
	{
		attr_table = out_attr_table,
	}

	self:send_to_gate(MID.c2s_role_attr_change_req, msg)
end

function Client:loop_random_change_attr()
	if self._loop_random_change_attr_timer_index then
		Env.timer_mgr:del_timer(self._loop_random_change_attr_timer_index)
		self._loop_random_change_attr_timer_index = nil
		return
	end

	local timer_cb = function()
		self:random_change_attr()
	end

	self._loop_random_change_attr_timer_index = Env.timer_mgr:add_timer(200, timer_cb, 0, true)
end

function Client:auto_run_cmd_once()
	
	if self._auto_run_cmd_timer_index then
		return
	end

	local cmd_list =
	{
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"9",
	}
	local cmd_index = 1
	local timer_cb = function()
		if cmd_index > #cmd_list then
			Env.timer_mgr:del_timer(self._auto_run_cmd_timer_index)
			return
		end
		
		ccall_stdin_handler(cmd_list[cmd_index])
		cmd_index = cmd_index + 1
	end

	self._auto_run_cmd_timer_index = Env.timer_mgr:add_timer(1000, timer_cb, 0, true)
	
end

function Client:x_test_start(num)
	self.g_x_test_num = num
	self.g_x_test_total_num = num
	self.g_x_test_start_time = LuaUtil:get_time_ms()
	self.g_x_test_total_time = 0
	self.g_x_test_min_time = 0
end

function Client:x_test_end()
	local time_ms = LuaUtil:get_time_ms()
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
