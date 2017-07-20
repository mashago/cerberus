
function send_to_login(msg_id, msg)
	ServiceClient.send_to_type_server(ServerType.LOGIN, msg_id, msg)
end

function send_to_router(msg_id, msg)
	ServiceClient.send_to_type_server(ServerType.ROUTER, msg_id, msg)
end

------------------------------------------------

g_x_test_num = -1 -- x test end
g_x_test_total_num = 0
g_x_test_start_time = 0
g_x_test_total_time = 0
g_x_test_min_time = 0

function x_test_start(num)
	g_x_test_num = num
	g_x_test_total_num = num
	g_x_test_start_time = get_time_ms_c()
	g_x_test_total_time = 0
	g_x_test_min_time = 0
end

function x_test_end()
	local time_ms = get_time_ms_c()
	if g_x_test_num > 0 then
		g_x_test_num = g_x_test_num - 1
		local time_ms_offset = time_ms - g_x_test_start_time
		g_x_test_total_time = g_x_test_total_time + time_ms_offset
		if g_x_test_min_time == 0 then
			g_x_test_min_time = time_ms_offset
		end
	end
	if g_x_test_num == 0 then
		Log.debug("******* x test time use time=%fms", time_ms - g_x_test_start_time)
		Log.debug("******* g_x_test_total_num=%d", g_x_test_total_num)
		Log.debug("******* g_x_test_total_time=%fms", g_x_test_total_time)
		Log.debug("******* average time=%fms", g_x_test_total_time/ g_x_test_total_num)
		Log.debug("******* min time=%fms", g_x_test_min_time)
		g_x_test_num = -1  -- x test end
	end
end

------------------------------------------------

local function handle_rpc_test(data, mailbox_id, msg_id)
	Log.debug("handle_rpc_test: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("handle_rpc_test: result=%s", ErrorCodeText[data.result])
	end
	x_test_end()
end

local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("handle_user_login: result=%s", ErrorCodeText[data.result])
	end
	x_test_end()
end

local function handle_area_list_ret(data, mailbox_id, msg_id)
	Log.debug("handle_area_list_ret: data=%s", Util.table_to_string(data))
end

local function handle_role_list_ret(data, mailbox_id, msg_id)
	Log.debug("handle_role_list_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("handle_role_list_ret: result=%s", ErrorCodeText[data.result])
	end
end

local function handle_create_role(data, mailbox_id, msg_id)
	Log.debug("handle_create_role: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("handle_create_role: result=%s", ErrorCodeText[data.result])
	end
end

local function handle_delete_role(data, mailbox_id, msg_id)
	Log.debug("handle_delete_role: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("handle_delete_role: result=%s", ErrorCodeText[data.result])
	end
end

g_role_info = {}

local function handle_select_role(data, mailbox_id, msg_id)
	Log.debug("handle_select_role: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("handle_select_role: result=%s", ErrorCodeText[data.result])
		return
	end

	g_role_info.ip = data.ip
	g_role_info.port = data.port
	g_role_info.user_id = data.user_id
	g_role_info.token = data.token

end

function register_msg_handler()
	Net.add_msg_handler(MID.RPC_TEST_RET, handle_rpc_test)

	Net.add_msg_handler(MID.USER_LOGIN_RET, handle_user_login)
	Net.add_msg_handler(MID.AREA_LIST_RET, handle_area_list_ret)
	Net.add_msg_handler(MID.ROLE_LIST_RET, handle_role_list_ret)
	Net.add_msg_handler(MID.CREATE_ROLE_RET, handle_create_role)
	Net.add_msg_handler(MID.DELETE_ROLE_RET, handle_delete_role)
	Net.add_msg_handler(MID.SELECT_ROLE_RET, handle_select_role)
end
