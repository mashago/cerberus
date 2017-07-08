

function handle_register_server(data, mailbox_id, msg_id)
	Log.debug("handle_register_server: data=%s", Util.table_to_string(data))

	-- add into server list
	-- send other server list to server
	-- db_svr will NOT broadcast register

	local msg = 
	{
		result = ErrorCode.SUCCESS,
		server_id = ServerConfig._server_id,
		server_type = ServerConfig._server_type,
	}

	-- add server
	local new_server_info = ServiceServer.add_server(mailbox_id, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)
	if not new_server_info then
		msg.result = ErrorCode.REGISTER_SERVER_FAIL
		Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, msg)
		return
	end

	new_server_info:send_msg(MID.REGISTER_SERVER_RET, msg)
end

function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, handle_register_server)
end
