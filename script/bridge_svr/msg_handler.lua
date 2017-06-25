

local function handle_register_server_ret(data, mailbox_id, msg_id)
	Log.debug("handle_register_server_ret: data=%s", Util.TableToString(data))
	if data.result ~= ServerErrorCode.SUCCESS then
		Log.err("handle_register_server_ret: register fail %d", data.result)
	end
	ServiceClient.register_success(mailbox_id, data.server_id, data.server_type)
end

local function handle_register_server_broadcast(data, mailbox_id, msg_id)
	Log.debug("handle_register_server_broadcast: data=%s", Util.TableToString(data))
	ServiceClient.add_server(mailbox_id, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)
end

local function handle_server_disconnect(data, mailbox_id, msg_id)
	Log.debug("handle_server_disconnect: data=%s", Util.TableToString(data))
	ServiceClient.remove_server(mailbox_id, data.server_id)
end

function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_RET, handle_register_server_ret)
	Net.add_msg_handler(MID.REGISTER_SERVER_BROADCAST, handle_register_server_broadcast)
	Net.add_msg_handler(MID.SERVER_DISCONNECT, handle_server_disconnect)
end
