
function g_net_event_server_disconnect(server_id)
	
end

function g_net_event_client_disconnect(mailbox_id)
	-- get user by mailbox_id
	local user = g_user_mgr:get_user_by_mailbox(mailbox_id)
	if not user then
		return
	end

	Log.info("g_net_event_client_disconnect: user_id=%d", user._user_id)
	return user:disconnect()
end

function g_net_event_transfer_msg(mailbox_id, msg_id, ext)
	Log.info("g_net_event_transfer_msg: mailbox_id=%d, msg_id=%d, ext=%d", mailbox_id, msg_id, ext)
	-- TODO transfer to client or server
end

--[[
function g_net_event_client_msg(handle_func, data, mailbox_id, msg_id)

	local user = g_user_mgr:get_user_by_mailbox(mailbox_id)
	if not user then
		Log.warn("g_net_event_client_msg: user nil msg_id=%d", msg_id)
		return
	end

	handle_func(user, data, mailbox_id, msg_id)
end
--]]
