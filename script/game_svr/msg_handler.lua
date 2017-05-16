
local function handle_client_test(data, mailbox_id, msg_id)
	Log.debug("client_time=%d client_data=%s", data.client_time, data.client_data)	
end

function register_msg_handler()
	Net.add_msg_handler(MID.CLIENT_TEST, handle_client_test)
end
