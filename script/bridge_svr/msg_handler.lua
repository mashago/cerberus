

local function handle_register_area_ret(data, mailbox_id, msg_id)
	Log.debug("handle_register_area_ret: data=%s", Util.TableToString(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.err("handle_register_area_ret: register fail %d", data.result)
		return
	end
end

function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_RET, g_funcs.handle_register_server_ret)
	Net.add_msg_handler(MID.REGISTER_SERVER_BROADCAST, g_funcs.handle_register_server_broadcast)
	Net.add_msg_handler(MID.SERVER_DISCONNECT, g_funcs.handle_server_disconnect)

	Net.add_msg_handler(MID.REGISTER_AREA_RET, handle_register_area_ret)
end
