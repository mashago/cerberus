
local function handle_shake_hand(data, mailbox_id)

	local server_id = data.server_id
	local server_type = data.server_type
	local single_scene_list = data.single_scene_list
	local from_to_scene_list = data.from_to_scene_list
	local ip = data.ip
	local port = data.port

	g_server_mgr:shake_hand(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list, ip, port)

end

local function register_msg_handler()
	Net.add_msg_handler(MID.SHAKE_HAND_REQ, handle_shake_hand)

end

register_msg_handler()
