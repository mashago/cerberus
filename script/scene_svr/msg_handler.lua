

local function handle_client_test(data, mailbox_id, msg_id)
	-- Log.debug("client_time=%d client_data=%s", data.client_time, data.client_data)	
	Log.debug("handle_client_test: data=%s", Util.TableToString(data))

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

local function handle_register_server_ret(data, mailbox_id, msg_id)
	Log.debug("handle_register_server_ret: data=%s", Util.TableToString(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.err("handle_register_server_ret: register fail %d", data.result)
		return
	end
	ServiceClient.register_success(mailbox_id, data.server_id, data.server_type)
end

local function handle_register_server_broadcast(data, mailbox_id, msg_id)
	Log.debug("handle_register_server_broadcast: data=%s", Util.TableToString(data))
	ServiceClient.add_server(mailbox_id, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)
end

local function handle_server_disconnect(data, mailbox_id, msg_id)
	Log.debug("handle_server_disconnect: data=%s", Util.TableToString(data))
	ServiceClient.remove_server(mailbox_id, data.server_id)
end

function register_msg_handler()
	Net.add_msg_handler(MID.CLIENT_TEST, handle_client_test)
	Net.add_msg_handler(MID.REGISTER_SERVER_RET, handle_register_server_ret)
	Net.add_msg_handler(MID.REGISTER_SERVER_BROADCAST, handle_register_server_broadcast)
	Net.add_msg_handler(MID.SERVER_DISCONNECT, handle_server_disconnect)
end
