
local Env = require "env"
local Log = require "core.log.logger"
local g_msg_handler = require "core.global.msg_handler"
local Util = require "core.util.util"
local MID = MID
local g_role_mgr = g_role_mgr
local ErrorCode = ErrorCode

function g_msg_handler.c2s_client_test_req(data, mailbox_id, msg_id)
	-- Log.debug("client_time=%d client_data=%s", data.client_time, data.client_data)	
	Log.debug("c2s_client_test_req: data=%s", Util.table_to_string(data))

	local msg =
	{
		byte = 65,
		bool = true,
		int = 123,
		float = 3.14,
		short = 56,
		int64 = 11111111111,
		string = "hello world 1",
		struct = 
		{
			byte = 66,
			bool = false,
			int = 456,
			float = 5.16,
			short = 78,
			int64 = 22222222222,
			string = "hello world 2",
		},

		bytearray = {67, 68, 69},
		boolarray = {true, false},
		intarray = {111111, 222222},
		floatarray = {1.1, 2.2},
		shortarray = {444, 555},
		int64array = {33333333333, 44444444444},
		stringarray = {"hello world 3", "hello world 4"},
		structarray = 
		{
			{
				byte = 70,
				bool = false,
				int = 456,
				float = 5.16,
				short = 78,
				int64 = 55555555555,
				string = "hello world 5",
			},
			{
				byte = 71,
				bool = false,
				int = 456,
				float = 5.16,
				short = 78,
				int64 = 66666666666,
				string = "hello world 6",
			},
		},

	}
	Env.net_mgr:send_msg(mailbox_id, MID.s2c_client_test_ret, msg)
end

function g_msg_handler.s2s_gate_role_enter_req(data, mailbox_id)
	Log.debug("s2s_gate_role_enter_req: mailbox_id=%d data=%s", mailbox_id, Util.table_to_string(data))

	local role_id = data.role_id
	local scene_id = data.scene_id

	-- 1. new role
	local role = g_role_mgr:get_role_by_id(role_id)
	if not role then
		local Role = require "scene_svr.role_obj"
		role = Role.new(role_id, mailbox_id)
		role:init()
		g_role_mgr:add_role(role)
	else
		Log.warn("s2s_gate_role_enter_req: role already exists %d", role_id)
	end
	
	-- 2. init role info
	role:load_and_init_data()

	-- 3. success to gate
	local msg = 
	{
		result = ErrorCode.SUCCESS,
		role_id = role_id,
	}
	local ret = Env.net_mgr:send_msg(mailbox_id, MID.s2s_gate_role_enter_ret, msg)

	-- 4. sync to client
	role:send_module_data()
end

function g_msg_handler.s2s_gate_role_disconnect(role, data, mailbox_id)

	Log.debug("s2s_gate_role_disconnect: role._role_id=%d", role._role_id)

	role:on_disconnect()

end

function g_msg_handler.c2s_role_attr_change_req(role, data, mailbox_id)
	-- Log.debug("c2s_role_attr_change_req data=%s", Util.table_to_string(data))
	local attr_table = data.attr_table
	-- Log.debug("c2s_role_attr_change_req attr_table=%s", Util.table_to_string(attr_table))

	role:modify_attr_table(attr_table)

end
