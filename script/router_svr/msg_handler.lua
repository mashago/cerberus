

local function handle_register_server(data, mailbox_id, msg_id)
	Log.debug("handle_register_server: data=%s", tableToString(data))

	Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, mailbox_id, data.server_type, data.scene_id)
end

function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, handle_register_server)
end
