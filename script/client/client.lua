
local server_conf = require "global.server_conf"
local server_mgr = require "server.server_mgr"
local timer_mgr = require "timer.timer"
local Log = require "log.logger"
local g_funcs = require "global.global_funcs"
local class = require "util.class"
local cutil = require "cerberus.util"
local msg_def = require "global.net_msg_def"
local global_define = require "global.global_define"
local ServerType = global_define.ServerType
local MID = msg_def.MID

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

function Client:load_server_list()
	local server_list = server_conf._config.server_list or {}
	for _, v in ipairs(server_list) do
		local server_id = v.id
		local server_type = v.type
		local ip = v.ip
		local port = v.port
		self._server_list[server_type] =
		{
			ip = ip,
			port = port,
			server_id = server_id,
		}
	end
end


function Client:send_to_login(msg_id, msg)
	server_mgr:send_by_server_type(ServerType.LOGIN, msg_id, msg)
end

function Client:send_to_gate(msg_id, msg)
	server_mgr:send_by_server_type(ServerType.GATE, msg_id, msg)
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
		timer_mgr:del_timer(self._loop_random_change_attr_timer_index)
		self._loop_random_change_attr_timer_index = nil
		return
	end

	local timer_cb = function()
		self:random_change_attr()
	end

	self._loop_random_change_attr_timer_index = timer_mgr:add_timer(200, timer_cb, 0, true)
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
			timer_mgr:del_timer(self._auto_run_cmd_timer_index)
			return
		end
		
		ccall_stdin_handler(cmd_list[cmd_index])
		cmd_index = cmd_index + 1
	end

	self._auto_run_cmd_timer_index = timer_mgr:add_timer(1000, timer_cb, 0, true)
	
end

function Client:x_test_start(num)
	self.g_x_test_num = num
	self.g_x_test_total_num = num
	self.g_x_test_start_time = cutil.get_time_ms()
	self.g_x_test_total_time = 0
	self.g_x_test_min_time = 0
end

function Client:x_test_end()
	local time_ms = cutil.get_time_ms()
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
