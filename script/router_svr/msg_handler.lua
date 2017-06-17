

local function handle_register_server(data, mailbox_id, msg_id)
	Log.debug("handle_register_server: data=%s", tableToString(data))

	-- check mailbox is trust
	-- add into server list
	-- broadcast to other server
	-- TODO
	
	local mailbox = Net.get_mailbox(mailbox_id)
	if not mailbox then
		Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, ServerErrorCode.REGISTER_FAIL)
		return
	end

	if mailbox.conn_type ~= ConnType.TRUST then
		Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, ServerErrorCode.REGISTER_UNTRUST)
		return
	end

	Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, ServerErrorCode.SUCCESS)

	Net.send_msg(mailbox_id, MID.REGISTER_SERVER_BROADCAST, mailbox_id, data.server_type, data.single_scene_id, data.from_to_scene_id)
end

function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, handle_register_server)
end
