
local function handle_register_server(data, mailbox_id)

	local server_id = data.server_id
	local server_type = data.server_type
	local single_scene_list = data.single_scene_list
	local from_to_scene_list = data.from_to_scene_list
	local ip = data.ip
	local port = data.port

	g_server_mgr:server_register(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list, ip, port)

end


local function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, handle_register_server)

end

register_msg_handler()
