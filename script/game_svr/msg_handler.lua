

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
	}
	Net.send_msg(mailbox_id, MID.CLIENT_TEST_RET, table.unpack(data_send))
end

function register_msg_handler()
	Net.add_msg_handler(MID.CLIENT_TEST, handle_client_test)
end
