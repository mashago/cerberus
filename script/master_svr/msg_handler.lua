
local g_msg_handler = require "core.global.msg_handler"
local Env = require "env"
function g_msg_handler.s2s_shake_hand_req(data, mailbox_id)

	local server_id = data.server_id
	local server_type = data.server_type
	local single_scene_list = data.single_scene_list
	local from_to_scene_list = data.from_to_scene_list
	local ip = data.ip
	local port = data.port

	Env.peer_mgr:shake_hand(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list, ip, port)

end

