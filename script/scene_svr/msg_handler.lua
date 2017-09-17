

local function handle_client_test(data, mailbox_id, msg_id)
	-- Log.debug("client_time=%d client_data=%s", data.client_time, data.client_data)	
	Log.debug("handle_client_test: data=%s", Util.table_to_string(data))

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
	Net.send_msg(mailbox_id, MID.CLIENT_TEST_RET, msg)
end

local function handle_router_role_enter_req(data, mailbox_id)
	local func = function(mailbox_id, data)
		
		Log.debug("handle_router_role_enter_req: mailbox_id=%d data=%s", mailbox_id, Util.table_to_string(data))

		local role_id = data.role_id
		local scene_id = data.scene_id

		-- 1. new role
		-- 2. init role attr
		-- 3. sync to client
		-- 5. success to router

		-- 1. new role
		local role = g_role_mgr:get_role_by_id(role_id)
		if not role then
			local Role = require "scene_svr.role"
			role = Role:new(role_id, mailbox_id)
			g_role_mgr:add_role(role)
		else
			Log.debug("handle_router_role_enter_req: role already exists %d", role_id)
		end
		
		-- 2. init role info
		role:load_and_init_data()
		role:send_module_data()

		-- 3. sync to client
		local msg =
		{
			role_id = role_id,
			scene_id = scene_id,
		}
		role:send_msg(MID.ROLE_ATTR_RET, msg)

		-- 4. success to router
		local msg = 
		{
			result = ErrorCode.SUCCESS,
			role_id = role_id,
		}
		local ret = Net.send_msg(mailbox_id, MID.ROUTER_ROLE_ENTER_RET, msg)
	end
	-- rpc warpper
	RpcMgr.run(func, mailbox_id, data)

end

local function handle_router_role_disconnect(role, data, mailbox_id)

	Log.debug("handle_router_role_disconnect: role._role_id=%d", role._role_id)

	g_role_mgr:del_role(role)

end

local function handle_invite_connect(data, mailbox_id)
	Log.debug("handle_invite_connect data=%s", Util.table_to_string(data))
	local ip = data.ip
	local port = data.port
	local server_id = 0
	local server_type = 0
	local register = 1
	local invite = 0
	local no_reconnect = 1
	ServiceClient.add_connect_service(ip, port, server_id, server_type, register, invite, no_reconnect)
	ServiceClient.create_connect_timer()
end

local function handle_role_attr_change_req(role, data, mailbox_id)
	Log.debug("handle_role_attr_change_req data=%s", Util.table_to_string(data))
end

local function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_RET, g_funcs.handle_register_server_ret)
	Net.add_msg_handler(MID.REGISTER_SERVER_BROADCAST, g_funcs.handle_register_server_broadcast)
	Net.add_msg_handler(MID.SERVER_DISCONNECT, g_funcs.handle_server_disconnect)

	Net.add_msg_handler(MID.CLIENT_TEST, handle_client_test)

	Net.add_msg_handler(MID.ROUTER_ROLE_ENTER_REQ, handle_router_role_enter_req)
	Net.add_msg_handler(MID.ROUTER_ROLE_DISCONNECT, handle_router_role_disconnect)

	Net.add_msg_handler(MID.INVITE_CONNECT_REQ, handle_invite_connect)

	Net.add_msg_handler(MID.ROLE_ATTR_CHANGE_REQ, handle_role_attr_change_req)
end

register_msg_handler()
