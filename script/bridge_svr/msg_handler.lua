

local function handle_register_area_ret(data, mailbox_id, msg_id)
	Log.debug("handle_register_area_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.err("handle_register_area_ret: register fail %d", data.result)
		return
	end
end

local function register_msg_handler()
	Net.add_msg_handler(MID.SHAKE_HAND_REQ, g_funcs.handle_shake_hand_req)
	Net.add_msg_handler(MID.SHAKE_HAND_RET, g_funcs.handle_shake_hand_ret)
	Net.add_msg_handler(MID.SHAKE_HAND_INVITE, g_funcs.handle_shake_hand_invite)

	Net.add_msg_handler(MID.REGISTER_AREA_RET, handle_register_area_ret)
end

-- call here then hotfix can init register
register_msg_handler()
