

local function handle_register_area_ret(data, mailbox_id, msg_id)
	Log.debug("handle_register_area_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.err("handle_register_area_ret: register fail %d", data.result)
		return
	end
end

local function register_msg_handler()
	Net.add_msg_handler(MID.s2s_shake_hand_req, g_funcs.handle_shake_hand_req)
	Net.add_msg_handler(MID.s2s_shake_hand_ret, g_funcs.handle_shake_hand_ret)
	Net.add_msg_handler(MID.s2s_shake_hand_invite, g_funcs.handle_shake_hand_invite)

	Net.add_msg_handler(MID.s2s_register_area_ret, handle_register_area_ret)
end

-- call here then hotfix can init register
register_msg_handler()
