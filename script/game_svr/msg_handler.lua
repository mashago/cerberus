

local function handle_client_test(data, mailbox_id, msg_id)
	-- Log.debug("client_time=%d client_data=%s", data.client_time, data.client_data)	
	Log.debug("handle_client_test: data=%s", tableToString(data))

	local data_send =
	{
		65,
		true,
		123,
		3.14,
		56,
		11111111111,
		"hello world 1",
		{
			66,
			false,
			456,
			5.16,
			78,
			22222222222,
			"hello world 2",
		},

		{67, 68, 69},
		{true, false},
		{111111, 222222},
		{1.1, 2.2},
		{444, 555},
		{33333333333, 44444444444},
		{"hello world 3", "hello world 4"},
		{
			{
				70,
				false,
				456,
				5.16,
				78,
				55555555555,
				"hello world 5",
			},
			{
				71,
				false,
				456,
				5.16,
				78,
				66666666666,
				"hello world 6",
			},
		},

	}
	Net.send_msg(mailbox_id, MID.CLIENT_TEST_RET, table.unpack(data_send))
end

local function handle_register_server_ret(data, mailbox_id, msg_id)
	Log.debug("handle_register_server_ret: data=%s", tableToString(data))
end

local function handle_register_server_broadcast(data, mailbox_id, msg_id)
	Log.debug("handle_register_server_broadcast: data=%s", tableToString(data))
end

function register_msg_handler()
	Net.add_msg_handler(MID.CLIENT_TEST, handle_client_test)
	Net.add_msg_handler(MID.REGISTER_SERVER_RET, handle_register_server_ret)
	Net.add_msg_handler(MID.REGISTER_SERVER_BROADCAST, handle_register_server_broadcast)
end
