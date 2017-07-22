
function g_net_event_server_disconnect(server_id)
end

function g_net_event_client_msg(handle_func, data, mailbox_id, msg_id, ext)

	local role_id = ext
	local role = g_role_mgr:get_role_by_id(role_id)
	if not role then
		Log.warn("g_net_event_client_msg: role nil msg_id=%d", msg_id)
		return
	end

	return handle_func(role, data, mailbox_id, msg_id)
end
