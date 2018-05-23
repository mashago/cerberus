
function g_net_event_server_connect(server_id)
	local server_info = g_server_mgr:get_server_by_id(server_id)
	if server_info._server_type == ServerType.BRIDGE then
		g_common_handler:add_sync_conn_num_timer()
	end
end

function g_net_event_server_disconnect(server_id)
	local server_info = g_server_mgr:get_server_by_id(server_id)
	if server_info._server_type == ServerType.MASTER then
	elseif server_info._server_type == ServerType.BRIDGE then
		g_common_handler:del_sync_conn_num_timer()
	end
end

function g_net_event_client_disconnect(mailbox_id)
	-- get user by mailbox_id
	local user = g_user_mgr:get_user_by_mailbox(mailbox_id)
	if not user then
		return
	end

	Log.info("g_net_event_client_disconnect: user_id=%d", user._user_id)
	return g_user_mgr:user_offline(user)
end

