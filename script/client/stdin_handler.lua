
local cmd_handler = {}

function cmd_handler.execute(buffer)
	Log.debug("buffer=%s", buffer)
	local params = Util.split_string(buffer, " ")
	Log.debug("params=%s", Util.table_to_string(params))


	if params[1] == "rpc" then
		cmd_handler.do_rpc_test(params)
	elseif params[1] == "rpcx" then
		cmd_handler.do_rpc_testx(params)

	
	elseif params[1] == "pserver" then
		cmd_handler.do_print_server_list(params)
	elseif params[1] == "connect" then
		cmd_handler.do_connect(params)
	elseif params[1] == "close" then
		cmd_handler.do_close_connect(params)

	elseif params[1] == "login" then
		cmd_handler.do_login(params)
	elseif params[1] == "loginx" then
		cmd_handler.do_loginx(params)
	elseif params[1] == "arealist" then
		cmd_handler.do_area_list_req(params)
	elseif params[1] == "rolelist" then
		cmd_handler.do_role_list_req(params)
	elseif params[1] == "create" then
		cmd_handler.do_create_role(params)
	elseif params[1] == "delete" then
		cmd_handler.do_delete_role(params)
	elseif params[1] == "select" then
		cmd_handler.do_select_role(params)

	elseif params[1] == "enter" then
		cmd_handler.do_enter(params)

	elseif params[1] == "http" then
		cmd_handler.do_http_request(params)

	elseif params[1] == "attr" then
		cmd_handler.do_attr_change(params)
	
	else
		Log.warn("unknow cmd")
	end

end

function cmd_handler.do_rpc_test(params)
	-- rpc [buff]
	if #params ~= 2 then
		Log.warn("cmd_handler.do_rpc_test params not enough")
		return
	end

	local msg =
	{
		buff = params[2],
	}

	send_to_login(MID.RPC_TEST_REQ, msg)
end

function cmd_handler.do_rpc_testx(params)

	-- rpcx [num]
	if #params ~= 2 then
		Log.warn("cmd_handler.do_rpc_testx params not enough")
		return
	end

	local num = tonumber(params[2])

	local msg =
	{
		buff = "aaa"
	}
	for i=1, num do
		send_to_login(MID.RPC_TEST_REQ, msg)
	end

	x_test_start(num)
end


function cmd_handler.do_print_server_list(params)
	Log.debug("cmd_handler.do_print_server_list server_list=%s", Util.table_to_string(g_client._server_list))
end

function cmd_handler.do_connect(params)
	-- connect [login/router]
	if #params < 2 then
		Log.warn("cmd_handler.do_connect params not enough")
		return
	end

	local server_type = nil
	if params[2] == "login" then
		server_type = ServerType.LOGIN
	elseif params[2] == "router" then
		server_type = ServerType.ROUTER
	end
	if not server_type then
		Log.warn("cmd_handler.do_connect server type nil")
		return
	end

	local server_info = g_client._server_list[server_type]
	if not server_info then
		Log.warn("cmd_handler.do_connect no such server info")
		return
	end

	local ip = server_info.ip
	local port = server_info.port
	local server_id = server_info.server_id
	local register = 0
	ServiceClient.add_connect_service(ip, port, server_id, server_type, register)

	ServiceClient.create_connect_timer()
end

function cmd_handler.do_close_connect(params)
	-- close [login/router]
	if #params < 2 then
		Log.warn("cmd_handler.do_close_connect params not enough")
		return
	end

	local server_type = nil
	if params[2] == "login" then
		server_type = ServerType.LOGIN
	elseif params[2] == "router" then
		server_type = ServerType.ROUTER
	end
	if not server_type then
		Log.warn("cmd_handler.do_close_connect no such service")
		return
	end

	ServiceClient.close_service_by_type(server_type)
end

function cmd_handler.do_login(params)
	-- login [username] [password] [channel_id]
	if #params < 3 then
		Log.warn("cmd_handler.do_login params not enough")
		return
	end

	local channel_id = tonumber(params[4] or 0)
	local msg =
	{
		username = params[2],
		password = params[3],
		channel_id = channel_id,
	}
	send_to_login(MID.USER_LOGIN_REQ, msg)

	x_test_start(1)
end

function cmd_handler.do_loginx(params)
	-- loginx [num]
	if #params ~= 2 then
		Log.warn("cmd_handler.do_loginx params not enough")
		return
	end

	local num = tonumber(params[2])

	for i=1, num do
		local x = math.random(1000000)
		local username = "test" .. tostring(x)

		local msg =
		{
			username = username,
			password = "qwerty",
			channel_id = 0,
		}
		send_to_login(MID.USER_LOGIN_REQ, msg)
	end

	x_test_start(num)

end

function cmd_handler.do_area_list_req(params)
	-- arealist
	send_to_login(MID.AREA_LIST_REQ)

	g_time_counter:start()
end

function cmd_handler.do_role_list_req(params)
	-- rolelist [opt area_id]
	local area_id = tonumber(params[2] or "1")

	local msg =
	{
		area_id = area_id
	}

	send_to_login(MID.ROLE_LIST_REQ, msg)

	g_time_counter:start()
end

function cmd_handler.do_create_role(params)
	-- create [role_name] [opt area_id]
	if #params < 2 then
		Log.warn("cmd_handler.do_create_role params not enough")
		return
	end

	local msg =
	{
		area_id = tonumber(params[3] or "1"),
		role_name = params[2],
	}

	send_to_login(MID.CREATE_ROLE_REQ, msg)

	g_time_counter:start()
end

function cmd_handler.do_delete_role(params)
	-- delete [role_id] [opt area_id]
	if #params < 2 then
		Log.warn("cmd_handler.do_delete_role params not enough")
		return
	end

	local msg =
	{
		area_id = tonumber(params[3] or "1"),
		role_id = tonumber(params[2]),
	}

	send_to_login(MID.DELETE_ROLE_REQ, msg)

	g_time_counter:start()
end

function cmd_handler.do_select_role(params)
	-- select [role_id] [opt area_id]
	if #params < 2 then
		Log.warn("cmd_handler.do_select_role params not enough")
		return
	end

	local msg =
	{
		area_id = tonumber(params[3] or "1"),
		role_id = tonumber(params[2]),
	}

	send_to_login(MID.SELECT_ROLE_REQ, msg)

	g_time_counter:start()
end

function cmd_handler.do_enter(params)
	-- enter
	local msg =
	{
		user_id = g_client._user_id,
		token = g_client._user_token,
	}

	send_to_router(MID.ROLE_ENTER_REQ, msg)

	g_time_counter:start()
end

function cmd_handler.do_http_request(params)
	-- http
	local url = "http://www.baidu.com"
	local session_id = 1
	local request_type = 1
	Net.http_request_get(url, session_id, request_type)
	-- Net.http_request_get(url, session_id, request_type)
	-- Net.http_request_get(url, session_id, request_type)
end

function cmd_handler.do_attr_change(params)
	-- attr [attr_name] [value]
	if #params < 3 then
		Log.warn("cmd_handler.do_attr_change params not enough")
		return
	end

	local attr_name = params[2]
	local attr_value = params[3]

	local attr_table = g_funcs.get_empty_attr_list_table()
	g_funcs.set_attr_table(attr_table, "role_info", attr_name, attr_value)

	Log.debug("cmd_handler.do_attr_change attr_table=%s", Util.table_to_string(attr_table))

	-- send_to_login(MID.SELECT_ROLE_REQ, msg)

end

function ccall_stdin_handler(buffer)
	Log.info("ccall_stdin_handler buffer=%s", buffer)

	local function error_handler(msg)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_stdin_handler error : \n%s", msg)
		return msg 
	end
	
	local status, msg = xpcall(cmd_handler.execute
	, function(msg) return error_handler(msg) end
	, buffer)

	if not status then
		Log.err(msg)
	end
end

return cmd_handler
