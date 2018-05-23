
g_msg_handler = g_msg_handler or {}

if g_server_type ~= ServerType.MASTER then
function g_msg_handler.s2s_shake_hand_req(data, mailbox_id)
	g_funcs.handle_shake_hand_req(data, mailbox_id)
end
end

function g_msg_handler.s2s_shake_hand_ret(data, mailbox_id)
	g_funcs.handle_shake_hand_ret(data, mailbox_id)
end

function g_msg_handler.s2s_shake_hand_invite(data, mailbox_id)
	g_funcs.handle_shake_hand_invite(data, mailbox_id)
end

function g_msg_handler.s2s_shake_hand_cancel(data, mailbox_id)
	return g_funcs.handle_shake_hand_cancel(data, mailbox_id)
end

function g_msg_handler.s2s_rpc_req()
	Log.err("s2s_rpc_req just take place should not enter")
end

function g_msg_handler.s2s_rpc_nocb_req()
	Log.err("s2s_rpc_nocb_req just take place should not enter")
end

function g_msg_handler.s2s_rpc_ret()
	Log.err("s2s_rpc_ret just take place should not enter")
end

return g_msg_handler
