
function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, g_funcs.handle_register_server)
end
