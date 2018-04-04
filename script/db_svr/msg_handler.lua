
local function register_msg_handler()
	Net.add_msg_handler(MID.s2s_shake_hand_req, g_funcs.handle_shake_hand_req)
	Net.add_msg_handler(MID.s2s_shake_hand_ret, g_funcs.handle_shake_hand_ret)
	Net.add_msg_handler(MID.s2s_shake_hand_invite, g_funcs.handle_shake_hand_invite)
end

register_msg_handler()
