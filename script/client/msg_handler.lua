
function send_to_login(msg_id, msg)
	ServiceClient.send_to_type_server(ServerType.LOGIN, msg_id, msg)
end

function send_to_router(msg_id, msg)
	ServiceClient.send_to_type_server(ServerType.ROUTER, msg_id, msg)
end


g_x_test_num = -1 -- x test end
g_x_test_start_time = 0
function x_test_start(num)
	g_x_test_num = num
	g_x_test_start_time = os.time()
end
function x_test_end()
	if g_x_test_num > 0 then
		g_x_test_num = g_x_test_num - 1
	end
	if g_x_test_num == 0 then
		Log.debug("******* x test time use time=%d", os.time() - g_x_test_start_time)
		g_x_test_num = -1  -- x test end
	end
end

local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))
	x_test_end()
end

local function handle_area_list_ret(data, mailbox_id, msg_id)
	Log.debug("handle_area_list_ret: data=%s", Util.TableToString(data))
end

local function handle_role_list_ret(data, mailbox_id, msg_id)
	Log.debug("handle_role_list_ret: data=%s", Util.TableToString(data))
end

local function handle_create_role(data, mailbox_id, msg_id)
	Log.debug("handle_create_role: data=%s", Util.TableToString(data))
end

local function handle_rpc_test(data, mailbox_id, msg_id)
	Log.debug("handle_rpc_test: data=%s", Util.TableToString(data))
	x_test_end()
end

function register_msg_handler()
	Net.add_msg_handler(MID.USER_LOGIN_RET, handle_user_login)
	Net.add_msg_handler(MID.AREA_LIST_RET, handle_area_list_ret)
	Net.add_msg_handler(MID.ROLE_LIST_RET, handle_role_list_ret)
	Net.add_msg_handler(MID.CREATE_ROLE_RET, handle_create_role)
	Net.add_msg_handler(MID.RPC_TEST_RET, handle_rpc_test)
end
