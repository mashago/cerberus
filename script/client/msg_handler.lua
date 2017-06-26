
function send_to_login(msg_id, ...)
	ServiceClient.send_to_type_server(ServerType.LOGIN, msg_id, ...)
end

function send_to_router(msg_id, ...)
	ServiceClient.send_to_type_server(ServerType.ROUTER, msg_id, ...)
end

local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))
end

local function handle_create_role(data, mailbox_id, msg_id)
	Log.debug("handle_create_role: data=%s", Util.TableToString(data))
end

local function handle_rpc_test(data, mailbox_id, msg_id)
	Log.debug("handle_rpc_test: data=%s", Util.TableToString(data))
end

function register_msg_handler()
	Net.add_msg_handler(MID.USER_LOGIN_RET, handle_user_login)
	Net.add_msg_handler(MID.CREATE_ROLE_RET, handle_create_role)
	Net.add_msg_handler(MID.RPC_TEST_RET, handle_rpc_test)
end
