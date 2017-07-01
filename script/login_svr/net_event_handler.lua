
function g_net_event_server_disconnect(server_id)
	AreaMgr.remove_by_server_id(server_id)
end

function g_net_event_client_disconnect(mailbox_id)
	-- get user by mailbox_id
	local user = UserMgr.get_user_by_mailbox(mailbox_id)
	if not user then
		return
	end

	Log.info("g_net_event_client_disconnect: user_id=%d", user._user_id)
	UserMgr.del_user(user)
end

function g_net_event_client_msg(handle_func, data, mailbox_id, msg_id)

	local user = UserMgr.get_user_by_mailbox(mailbox_id)
	if not user then
		Log.warn("g_net_event_client_msg: user nil msg_id=%d", msg_id)
		return
	end

	handle_func(user, data, mailbox_id, msg_id)
end
