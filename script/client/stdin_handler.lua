
local cmd_handler = {}

function cmd_handler.execute(buffer)
	Log.debug("buffer=%s", buffer)
	local params = Util.split_string(buffer, " ")
	Log.debug("params=%s", Util.table_to_string(params))

	if params[1] == "test" then
		cmd_handler.do_test(params)

	elseif params[1] == "help" then
		cmd_handler.print_all_cmd()

	elseif params[1] == "rpc" then
		cmd_handler.do_rpc_test(params)
	elseif params[1] == "rpcx" then
		cmd_handler.do_rpc_testx(params)
	elseif params[1] == "rpcnocb" then
		cmd_handler.do_rpc_nocb_test(params)
	elseif params[1] == "rpcnocbx" then
		cmd_handler.do_rpc_nocb_testx(params)
	elseif params[1] == "rpcmix" then
		cmd_handler.do_rpc_mix_test(params)
	elseif params[1] == "rpcmixx" then
		cmd_handler.do_rpc_mix_testx(params)

	
	elseif params[1] == "pserver" then
		cmd_handler.do_print_server_list(params)
	elseif params[1] == "c" then
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
	elseif params[1] == "roleprint" then
		cmd_handler.do_role_print(params)

	elseif params[1] == "testobj" then
		cmd_handler.do_test_obj(params)
	
	else
		Log.warn("unknow cmd")
	end

end

function cmd_handler.test3_cb()
	-- Log.warn("xxxxxxx cmd_handler test3_cb\n")
	Log.warn("xxxxxxx cmd_handler test3_cb xxxxxxx\n")
end

function cmd_handler.test3_cb2()
	-- Log.warn("@@@@@@@ cmd_handler test3_cb2\n")
	Log.warn("@@@@@@@ cmd_handler test3_cb2 @@@@@@@\n")
end

function cmd_handler.test3_cb3()
	-- Log.warn("******* cmd_handler test3_cb3\n")
	Log.warn("******* cmd_handler test3_cb3 *******\n")
end

local tmp_local_x = 100
local tmp_local_x2 = tmp_local_x2 or 200
tmp_global_y = 300
tmp_global_y2 = tmp_global_y2 or 400 -- if want to keep global after hotfix, must use "g_var = g_var or x", if want to update global var, just use 'g_var = x'

local test3_timer_index_list = {}

function cmd_handler.do_test(params)

	-- test [n]
	if #params < 2 then
		Log.warn("cmd_handler.do_test params not enough")
		return
	end

	local testn = tonumber(params[2]) or 1

	local last_params = {}
	if table.move then
		table.move(params, 3, #params, 1, last_params)
	else
		for i=1, #params-2 do
			last_params[i] = params[i+2]
		end
	end

	local switch =
	{
		[1] = function(last_params)
			Log.debug("tmp_local_x=%d", tmp_local_x)
			Log.debug("tmp_local_x2=%d", tmp_local_x2)
			Log.debug("tmp_global_y=%d", tmp_global_y)
			Log.debug("tmp_global_y2=%d", tmp_global_y2)
		end,

		[2] = function(last_params)
			tmp_local_x = tmp_local_x + 1
			tmp_local_x2 = tmp_local_x2 + 1
			tmp_global_y = tmp_global_y + 1
			tmp_global_y2 = tmp_global_y2 + 1
		end,

		[3] = function(last_params)
			-- test hotfix timer cb
			
			if next(test3_timer_index_list) then
				Log.debug("delete test3 timer")
				for k, v in ipairs(test3_timer_index_list) do
					g_timer:del_timer(v)
				end
				test3_timer_index_list = {}
				return
			end

			-- closure cb
			-- cannot hotfix
			local timer_cb = function()
				-- Log.warn("####### test3 closure cb\n")
				Log.warn("####### test3 closure cb #######\n")
			end
			table.insert(test3_timer_index_list, g_timer:add_timer(5 * 1000, timer_cb, 0, true))

			-- closure cb call obj function
			-- closure cannot hotfix, obj function can hotfix
			local timer_cb2 = function()
				-- Log.warn("&&&&&&& test3 call obj function")
				Log.warn("&&&&&&& test3 call obj function &&&&&&&")
				Log.warn("cmd_handler=%s cmd_handler.test3_cb=%s", cmd_handler, cmd_handler.test3_cb)
				cmd_handler.test3_cb()
			end
			table.insert(test3_timer_index_list, g_timer:add_timer(5 * 1000, timer_cb2, 0, true))

			-- obj cb
			-- can hotfix
			table.insert(test3_timer_index_list, g_timer:add_timer(5 * 1000, cmd_handler.test3_cb2, 0, true))

			local timer_cb3 = cmd_handler.test3_cb3
			table.insert(test3_timer_index_list, g_timer:add_timer(5 * 1000, timer_cb3, 0, true))

		end,
	}

	local func = switch[testn]
	if not func then
		Log.warn("cmd_handler.do_test no such test function %d", testn)
		return
	end

	func(last_params)

end

function cmd_handler.print_all_cmd()

	local words = [[
	rpc [buffer]
	rpcx [num]
	c [login/gate]
	close [login/gate]
	login [username] [password] [channel_id]
	loginx [num]
	arealist
	rolelist
	create [role_name] [opt area_id]
	delete [role_id] [opt area_id]
	select [role_id] [opt area_id]
	enter
	http
	attr [attr_name] [value]
]]

	Log.info("cmd_handler.print_all_cmd()\n%s", words)
end

function cmd_handler.do_rpc_test(params)
	-- rpc [buff]
	local buff = "aaa"
	if #params >= 2 then
		buff = params[2]
	end

	local msg =
	{
		buff = buff,
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

function cmd_handler.do_rpc_nocb_test(params)
	-- rpcnocb [buff]
	local buff = "bbb"
	if #params >= 2 then
		buff = params[2]
	end

	local msg =
	{
		buff = buff,
	}

	send_to_login(MID.RPC_NOCB_TEST_REQ, msg)
end

function cmd_handler.do_rpc_nocb_testx(params)

	-- rpcnocbx [num]
	if #params ~= 2 then
		Log.warn("cmd_handler.do_rpc_nocb_testx params not enough")
		return
	end

	local num = tonumber(params[2])

	local msg =
	{
		buff = "bbb"
	}
	for i=1, num do
		send_to_login(MID.RPC_NOCB_TEST_REQ, msg)
	end
end

function cmd_handler.do_rpc_mix_test(params)
	-- rpcmix [buff]
	local buff = "ccc"
	if #params >= 2 then
		buff = params[2]
	end

	local msg =
	{
		buff = buff,
	}

	send_to_login(MID.RPC_MIX_TEST_REQ, msg)
end

function cmd_handler.do_rpc_mix_testx(params)

	-- rpcmixx [num]
	if #params ~= 2 then
		Log.warn("cmd_handler.do_rpc_mix_testx params not enough")
		return
	end

	local num = tonumber(params[2])

	local msg =
	{
		buff = "ccc"
	}
	for i=1, num do
		send_to_login(MID.RPC_MIX_TEST_REQ, msg)
	end

	x_test_start(num)
end

---------------------------------------

function cmd_handler.do_print_server_list(params)
	Log.debug("cmd_handler.do_print_server_list server_list=%s", Util.table_to_string(g_client._server_list))
end

function cmd_handler.do_connect(params)
	-- c [login/gate]
	if #params < 2 then
		Log.warn("cmd_handler.do_connect params not enough")
		return
	end

	local server_type = nil
	if params[2] == "login" then
		server_type = ServerType.LOGIN
	elseif params[2] == "gate" then
		server_type = ServerType.GATE
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
	local no_shakehand = 1
	local no_reconnect = 0
	local no_delay = 1
	g_service_mgr:do_connect(ip, port, server_id, server_type, no_shakehand, no_reconnect, no_delay)

end

function cmd_handler.do_close_connect(params)
	-- close [login/gate]
	if #params < 2 then
		Log.warn("cmd_handler.do_close_connect params not enough")
		return
	end

	local server_type = nil
	if params[2] == "login" then
		server_type = ServerType.LOGIN
	elseif params[2] == "gate" then
		server_type = ServerType.GATE
	end
	if not server_type then
		Log.warn("cmd_handler.do_close_connect no such service")
		return
	end

	g_service_mgr:close_connection_by_type(server_type)
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
	-- rolelist 

	local msg =
	{
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

	send_to_gate(MID.ROLE_ENTER_REQ, msg)

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

	local out_attr_table = g_funcs.get_empty_attr_table()
	local table_def = DataStructDef.data.role_info

	for n=2, math.huge, 2 do
		local attr_name = params[n]
		local attr_str = params[n+1]
		if not attr_name or not attr_str then
			break
		end
		local field_def = table_def[attr_name]
		if not field_def then
			break
		end
		local value = g_funcs.str_to_value(attr_str, field_def.type)
		if value == nil then
			Log.warn("cmd_handler.do_attr_change attr convert fail %s %s", attr_name, attr_str)
			break
		end
		g_funcs.set_attr_table(out_attr_table, table_def, attr_name, value)
	end

	Log.debug("cmd_handler.do_attr_change out_attr_table=%s", Util.table_to_string(out_attr_table))

	local msg =
	{
		attr_table = out_attr_table,
	}

	send_to_gate(MID.ROLE_ATTR_CHANGE_REQ, msg)
end

function cmd_handler.do_role_print(params)
	-- roleprint
	if not g_role then
		Log.warn("cmd_handler.do_role_print g_role nil")
		return
	end
	g_role:print()
end

function cmd_handler.do_test_obj(params)
	local role_id = 1
	if not g_test_obj then
		local SheetObj = require "core.obj.sheet_obj"
		g_test_obj = SheetObj.new()
		g_test_obj:init("testobj", nil, 1)
		local db_record = 
		{
			[1] =
			{
				role_id = role_id,
				item_id = 1001,
				num = 1,
				attr = 101,
			},
			[2] =
			{
				role_id = role_id,
				item_id = 1002,
				num = 2,
				attr = 201,
			},
		}
		g_test_obj:init_data(db_record)
		g_test_obj:print()
	end

	-- modify
	do
		Log.debug("******* 1")
		g_test_obj:modify("num", 20, 1001)
		g_test_obj:print()

		Log.debug("******* 2")
		g_test_obj:modify("attr", 102, 1001)
		g_test_obj:print()
	end

	-- insert
	do
		Log.debug("******* 3")
		g_test_obj:insert(
			{
				role_id = role_id,
				item_id = 1003,
				num = 3,
				attr = 301,
			})
		g_test_obj:print()

		Log.debug("******* 4")
		g_test_obj:insert(
			{
				role_id = role_id,
				item_id = 1004,
				num = 4,
				attr = 401,
			})
		g_test_obj:print()
	end

	-- delete
	do
		-- delete modify row
		Log.debug("******* 5")
		g_test_obj:delete(1001)
		g_test_obj:print()

		-- delete normal row
		Log.debug("******* 6")
		g_test_obj:delete(1002)
		g_test_obj:print()

		-- delete insert row
		Log.debug("******* 7")
		g_test_obj:delete(1003)
		g_test_obj:print()
	end

	do 
		-- modify insert row
		Log.debug("******* 8")
		g_test_obj:modify("attr", 402, 1004)
		g_test_obj:print()
	end

	-- insert
	do
		-- insert delete row
		Log.debug("******* 9")
		g_test_obj:insert(
			{
				role_id = role_id,
				item_id = 1001,
				num = 10,
				attr = 101,
			})
		g_test_obj:print()

		Log.debug("******* 10")
		g_test_obj:insert(
			{
				role_id = role_id,
				item_id = 1002,
				num = 11,
				attr = 201,
			})
		g_test_obj:print()
	end

	g_test_obj:collect_dirty()

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
