

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

function handle_db_delete(data, mailbox_id, msg_id)
	Log.debug("handle_db_delete: data=%s", Util.table_to_string(data))

	local db_name = data.db_name
	local table_name = data.table_name
	local conditions = Util.unserialize(data.conditions)
	Log.debug("handle_db_delete conditions=%s", Util.table_to_string(conditions))

	local ret = DBMgr.do_delete(db_name, table_name, conditions)

	Log.debug("handle_db_delete ret=%d", ret)
end

function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, handle_register_server)

	Net.add_msg_handler(MID.DB_DELETE, handle_db_delete)
end
