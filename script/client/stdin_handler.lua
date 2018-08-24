
local Core = require "core"
local Log = require "core.log.logger"
local Util = require "core.util.util"
local g_funcs = require "core.global.global_funcs"
local cmd_handler = {}

function cmd_handler.execute(buffer)
	Log.debug("buffer=%s", buffer)
	if not buffer then
		Log.warn("cmd_handler.execute buffer nil")
		return
	end
	local input_list = Util.split_string(buffer, " ")

	local cmd = input_list[1] or "nil"
	local params = { table.unpack(input_list, 2)}
	Log.debug("cmd=%s params=%s", cmd, Util.table_to_string(params))


	if cmd == "test" then
		cmd_handler.do_test(params)

	elseif cmd == "help" then
		cmd_handler.print_all_cmd()

	elseif cmd == "rpc" then
		cmd_handler.do_rpc_test(params)
	elseif cmd == "rpcx" then
		cmd_handler.do_rpc_testx(params)
	elseif cmd == "rpcnocb" then
		cmd_handler.do_rpc_nocb_test(params)
	elseif cmd == "rpcnocbx" then
		cmd_handler.do_rpc_nocb_testx(params)
	elseif cmd == "rpcmix" then
		cmd_handler.do_rpc_mix_test(params)
	elseif cmd == "rpcmixx" then
		cmd_handler.do_rpc_mix_testx(params)

	elseif cmd == "1" then
		params = {"login"}
		cmd_handler.do_connect(params)
	elseif cmd == "2" then
		params = {}
		cmd_handler.do_login(params)
	elseif cmd == "3" then
		params = {}
		cmd_handler.do_role_list_req(params)
	elseif cmd == "4" then
		params = {}
		cmd_handler.do_create_role(params)
	elseif cmd == "5" then
		local area_id = nil
		local role_id = nil
		for k, v in ipairs(g_client._area_role_list) do
			for _, role in ipairs(v.role_list) do
				area_id = v.area_id
				role_id = role.role_id
				break
			end
		end

		if not role_id then
			return
		end
		params = {role_id, area_id}
		cmd_handler.do_select_role(params)
	elseif cmd == "6" then
		params = {"gate"}
		cmd_handler.do_connect(params)
	elseif cmd == "7" then
		params = {}
		cmd_handler.do_enter(params)
	elseif cmd == "8" then
		params = {}
		cmd_handler.do_random_attr_change(params)
	elseif cmd == "9" then
		params = {}
		cmd_handler.do_loop_random_attr_change(params)
	
	elseif cmd == "pserver" then
		cmd_handler.do_print_server_list(params)
	elseif cmd == "netprint" then
		cmd_handler.do_netprint(params)
	elseif cmd == "c" then
		cmd_handler.do_connect(params)
	elseif cmd == "close" then
		cmd_handler.do_close_connect(params)

	elseif cmd == "login" then
		cmd_handler.do_login(params)
	elseif cmd == "loginx" then
		cmd_handler.do_loginx(params)
	elseif cmd == "arealist" then
		cmd_handler.do_area_list_req(params)
	elseif cmd == "rolelist" then
		cmd_handler.do_role_list_req(params)
	elseif cmd == "create" then
		cmd_handler.do_create_role(params)
	elseif cmd == "delete" then
		cmd_handler.do_delete_role(params)
	elseif cmd == "select" then
		cmd_handler.do_select_role(params)

	elseif cmd == "enter" then
		cmd_handler.do_enter(params)

	elseif cmd == "http" then
		cmd_handler.do_http_request(params)

	elseif cmd == "attr" then
		cmd_handler.do_attr_change(params)
	elseif cmd == "attrx" then
		cmd_handler.do_attr_changex(params)
	elseif cmd == "randomattr" then
		cmd_handler.do_random_attr_change(params)
	elseif cmd == "looprandomattr" then
		cmd_handler.do_loop_random_attr_change(params)

	elseif cmd == "roleprint" then
		cmd_handler.do_role_print(params)

	elseif cmd == "testrole" then
		cmd_handler.do_test_role(params)
	elseif cmd == "testbag" then
		cmd_handler.do_test_bag(params)
	
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

-- [n]
function cmd_handler.do_test(params)

	if #params < 1 then
		Log.warn("cmd_handler.do_test params not enough")
		return
	end

	local testn = tonumber(params[1]) or 1

	local last_params = {}
	if table.move then
		table.move(params, 2, #params, 1, last_params)
	else
		for i=1, #params-1 do
			last_params[i] = params[i+1]
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
					Core.timer_mgr:del_timer(v)
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
			table.insert(test3_timer_index_list, Core.timer_mgr:add_timer(5 * 1000, timer_cb, 0, true))

			-- closure cb call obj function
			-- closure cannot hotfix, obj function can hotfix
			local timer_cb2 = function()
				-- Log.warn("&&&&&&& test3 call obj function")
				Log.warn("&&&&&&& test3 call obj function &&&&&&&")
				Log.warn("cmd_handler=%s cmd_handler.test3_cb=%s", cmd_handler, cmd_handler.test3_cb)
				cmd_handler.test3_cb()
			end
			table.insert(test3_timer_index_list, Core.timer_mgr:add_timer(5 * 1000, timer_cb2, 0, true))

			-- obj cb
			-- can hotfix
			table.insert(test3_timer_index_list, Core.timer_mgr:add_timer(5 * 1000, cmd_handler.test3_cb2, 0, true))

			local timer_cb3 = cmd_handler.test3_cb3
			table.insert(test3_timer_index_list, Core.timer_mgr:add_timer(5 * 1000, timer_cb3, 0, true))

		end,

		[4] = function(last_params)

			local time_ms = LuaUtil:get_time_ms()
			Log.debug("time_ms=%d", time_ms)
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

-- [buff]
function cmd_handler.do_rpc_test(params)
	local buff = "aaa"
	if #params >= 1 then
		buff = params[1]
	end

	local msg =
	{
		buff = buff,
	}

	g_client:send_to_login(MID.c2s_rpc_test_req, msg)
end

-- [num]
function cmd_handler.do_rpc_testx(params)

	if #params ~= 1 then
		Log.warn("cmd_handler.do_rpc_testx params not enough")
		return
	end

	local num = tonumber(params[1])

	local msg =
	{
		buff = "aaa"
	}
	for i=1, num do
		g_client:send_to_login(MID.c2s_rpc_test_req, msg)
	end

	g_client:x_test_start(num)
end

-- [buff]
function cmd_handler.do_rpc_nocb_test(params)
	local buff = "bbb"
	if #params >= 1 then
		buff = params[1]
	end

	local msg =
	{
		buff = buff,
	}

	g_client:send_to_login(MID.c2s_rpc_nocb_test_req, msg)
end

-- [num]
function cmd_handler.do_rpc_nocb_testx(params)

	if #params ~= 1 then
		Log.warn("cmd_handler.do_rpc_nocb_testx params not enough")
		return
	end

	local num = tonumber(params[1])

	local msg =
	{
		buff = "bbb"
	}
	for i=1, num do
		g_client:send_to_login(MID.c2s_rpc_nocb_test_req, msg)
	end
end

-- [buff]
function cmd_handler.do_rpc_mix_test(params)
	local buff = "ccc"
	if #params >= 1 then
		buff = params[1]
	end

	local msg =
	{
		buff = buff,
	}

	g_client:send_to_login(MID.c2s_rpc_mix_test_req, msg)
end

-- [num]
function cmd_handler.do_rpc_mix_testx(params)

	if #params ~= 1 then
		Log.warn("cmd_handler.do_rpc_mix_testx params not enough")
		return
	end

	local num = tonumber(params[1])

	local msg =
	{
		buff = "ccc"
	}
	for i=1, num do
		g_client:send_to_login(MID.c2s_rpc_mix_test_req, msg)
	end

	g_client:x_test_start(num)
end

---------------------------------------

function cmd_handler.do_print_server_list(params)
	Log.debug("cmd_handler.do_print_server_list server_list=%s", Util.table_to_string(g_client._server_list))
end

function cmd_handler.do_netprint(params)
	Core.server_mgr:print()
end

-- [login/gate]
function cmd_handler.do_connect(params)
	if #params < 1 then
		Log.warn("cmd_handler.do_connect params not enough")
		return
	end

	local server_type = nil
	if params[1] == "login" then
		server_type = ServerType.LOGIN
	elseif params[1] == "gate" then
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
	local no_shakehand = true
	local no_reconnect = false
	local no_delay = true
	Core.server_mgr:do_connect(ip, port, server_id, server_type, no_shakehand, no_reconnect, no_delay)

end

-- [login/gate]
function cmd_handler.do_close_connect(params)
	if #params < 1 then
		Log.warn("cmd_handler.do_close_connect params not enough")
		return
	end

	local server_type = nil
	if params[1] == "login" then
		server_type = ServerType.LOGIN
	elseif params[1] == "gate" then
		server_type = ServerType.GATE
	end
	if not server_type then
		Log.warn("cmd_handler.do_close_connect no such server")
		return
	end

	Core.server_mgr:close_connection_by_type(server_type, true)
end

-- [opt username] [opt password] [opt channel_id]
function cmd_handler.do_login(params)

	local username = params[1]
	local password = params[2]
	local channel_id = tonumber(params[3] or 0)

	if not username then
		username = g_funcs.gen_random_name()
	end

	if not password then
		password = "123456"
	end

	local msg =
	{
		username = username,
		password = password,
		channel_id = channel_id,
	}
	g_client:send_to_login(MID.c2s_user_login_req, msg)

	g_client:x_test_start(1)
end

-- [num]
function cmd_handler.do_loginx(params)
	if #params ~= 1 then
		Log.warn("cmd_handler.do_loginx params not enough")
		return
	end

	local num = tonumber(params[1])
	local str_date = os.date("%Y%m%d%H%M%S")

	for i=1, num do
		local username = "t" .. str_date .. i

		local msg =
		{
			username = username,
			password = "qwerty",
			channel_id = 0,
		}
		g_client:send_to_login(MID.c2s_user_login_req, msg)
	end

	g_client:x_test_start(num)

end

function cmd_handler.do_area_list_req(params)
	g_client:send_to_login(MID.c2s_area_list_req)

	g_time_counter:start()
end

function cmd_handler.do_role_list_req(params)

	local msg =
	{
	}

	g_client:send_to_login(MID.c2s_role_list_req, msg)

	g_time_counter:start()
end

-- [opt role_name] [opt area_id]
function cmd_handler.do_create_role(params)

	local role_name = params[1]
	if not role_name then
		role_name = g_funcs.gen_random_name()
	end

	local msg =
	{
		area_id = tonumber(params[2] or "1"),
		role_name = role_name
	}

	g_client:send_to_login(MID.c2s_create_role_req, msg)

	g_time_counter:start()
end

-- [role_id] [opt area_id]
function cmd_handler.do_delete_role(params)
	if #params < 1 then
		Log.warn("cmd_handler.do_delete_role params not enough")
		return
	end

	local msg =
	{
		area_id = tonumber(params[2] or "1"),
		role_id = tonumber(params[1]),
	}

	g_client:send_to_login(MID.c2s_delete_role_req, msg)

	g_time_counter:start()
end

-- [role_id] [opt area_id]
function cmd_handler.do_select_role(params)
	if #params < 1 then
		Log.warn("cmd_handler.do_select_role params not enough")
		return
	end

	local msg =
	{
		area_id = tonumber(params[2] or "1"),
		role_id = tonumber(params[1]),
	}
	Log.debug("cmd_handler.do_select_role role_id=%d, area_id=%d", msg.role_id, msg.area_id) 

	g_client:send_to_login(MID.c2s_select_role_req, msg)

	g_time_counter:start()
end

function cmd_handler.do_enter(params)
	-- enter
	local msg =
	{
		user_id = g_client._user_id,
		token = g_client._user_token,
	}

	g_client:send_to_gate(MID.c2s_role_enter_req, msg)

	g_time_counter:start()
end

function cmd_handler.do_http_request(params)
	-- http [url]
	local url = "http://www.sina.com.cn"
	-- local url = "http://www.qq.com"
	if params[1] then
		url = "http://" .. params[1]
	end
	local cb = function(response_code, content)
		Log.debug("cmd_handler.do_http_request url=%s response_code=%d", url, response_code)
	end
	Core.http_mgr:request_get(url, cb)
end

-- [attr_name] [value]
function cmd_handler.do_attr_change(params)
	if #params < 2 then
		Log.warn("cmd_handler.do_attr_change params not enough")
		return
	end

	local out_attr_table = g_funcs.get_empty_attr_table()
	local table_def = DataStructDef.data.role_info

	for n=1, math.huge, 2 do
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

	g_client:send_to_gate(MID.c2s_role_attr_change_req, msg)
	g_client:x_test_start(1)
end

-- [num] [attr_name] [value]
function cmd_handler.do_attr_changex(params)
	if #params < 3 then
		Log.warn("cmd_handler.do_attr_changex params not enough")
		return
	end

	Log.debug("do_attr_changex params=%s", Util.table_to_string(params))
	local num = tonumber(params[1]) or 1

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
			Log.warn("cmd_handler.do_attr_changex attr convert fail %s %s", attr_name, attr_str)
			break
		end
		g_funcs.set_attr_table(out_attr_table, table_def, attr_name, value)
	end

	Log.debug("cmd_handler.do_attr_changex out_attr_table=%s", Util.table_to_string(out_attr_table))

	for i = 1, num do
		local msg =
		{
			attr_table = out_attr_table,
		}

		g_client:send_to_gate(MID.c2s_role_attr_change_req, msg)
	end
	g_client:x_test_start(1)
end

function cmd_handler.do_random_attr_change(params)
	g_client:random_change_attr()
end

function cmd_handler.do_loop_random_attr_change(params)
	g_client:loop_random_change_attr()
end

function cmd_handler.do_role_print(params)
	-- roleprint
	if not g_role then
		Log.warn("cmd_handler.do_role_print g_role nil")
		return
	end
	g_role:print()
end

function cmd_handler.do_test_role(params)
	local role_id = 10000
	require("client.test_role")

	local test_role = TestRole.new(role_id)
	test_role:init()
	-- Log.debug("test_role = %s", Util.table_to_string(test_role))

	local db_record = 
	{
		[1] =
		{
			role_id = role_id,
			save_attr = 131,
			sync_save_attr = 141,
		},
	}
	test_role:init_data(db_record)
	test_role:print()

	-- modify
	do
		Log.debug("******* 1")
		test_role:set_sync_attr(122)
		test_role:set_save_attr(132)
		test_role:set_sync_save_attr(142)
		test_role:set_tmp_attr(152)
		test_role:print()
	end

	test_role:sync_dirty()
	test_role:save_dirty()

	Log.debug("********************")

	local role_id = 20000
	local test_role2 = TestRole.new(role_id)
	test_role2:init()
	-- Log.debug("test_role2 = %s", Util.table_to_string(test_role2))

	local db_record = 
	{
		[1] =
		{
			role_id = role_id,
			save_attr = 231,
			sync_save_attr = 241,
		},
	}
	test_role2:init_data(db_record)
	test_role2:print()

	-- modify
	do
		Log.debug("******* 2")
		test_role2:set_sync_attr(222)
		test_role2:set_save_attr(232)
		test_role2:set_sync_save_attr(242)
		test_role2:set_tmp_attr(152)
		test_role2:print()
	end

	test_role2:sync_dirty()
	test_role2:save_dirty()
end

function cmd_handler.do_test_bag(params)
	local role_id = 10000
	require("client.test_bag")
	local test_bag = TestBag.new(role_id)
	test_bag:init()
	Log.debug("test_bag = %s", Util.table_to_string(test_bag))

	local db_record = 
	{
		[1] =
		{
			role_id = role_id,
			item_id = 1001,
			num = 131,
			save_attr = 151,
			sync_save_attr = 161,
		},
		[2] =
		{
			role_id = role_id,
			item_id = 1002,
			num = 231,
			save_attr = 251,
			sync_save_attr = 261,
		},
	}
	test_bag:init_data(db_record)
	test_bag:print()

	-- modify
	do
		Log.debug("******* 1")
		test_bag:set_num(132, 1001)
		test_bag:set_sync_attr(142, 1001)
		test_bag:set_save_attr(152, 1001)
		test_bag:set_sync_save_attr(162, 1001)
		test_bag:set_tmp_attr(172, 1001)

		Log.debug("******* 2")
		test_bag:set_num(232, 1002)
		test_bag:set_sync_attr(242, 1002)
		test_bag:set_save_attr(252, 1002)
		test_bag:set_sync_save_attr(262, 1002)
		test_bag:set_tmp_attr(272, 1002)
		test_bag:print()

		Log.debug("1002 save_attr=%d", test_bag:get_save_attr(1002))
	end

	-- insert
	do
		Log.debug("******* 3")
		test_bag:insert(
			{
				role_id = role_id,
				item_id = 1003,
				num = 331,
				sync_attr = 341,
				save_attr = 351,
				sync_save_attr = 361,
				tmp_attr = 371,
			})

		Log.debug("******* 4")
		test_bag:insert(
			{
				role_id = role_id,
				item_id = 1004,
				num = 431,
				sync_attr = 441,
				save_attr = 451,
				sync_save_attr = 461,
				tmp_attr = 471,
			})
		test_bag:print()
	end

	-- delete
	do
		-- delete modify row
		Log.debug("******* 5")
		test_bag:delete(1001)

		-- delete normal row
		Log.debug("******* 6")
		test_bag:delete(1002)

		-- delete insert row
		Log.debug("******* 7")
		test_bag:delete(1003)
		test_bag:print()
	end

	do 
		-- modify insert row
		Log.debug("******* 8")
		test_bag:set_num(433, 1004)
		test_bag:set_sync_attr(443, 1004)
		test_bag:set_save_attr(453, 1004)
		test_bag:set_sync_save_attr(463, 1004)
		test_bag:set_tmp_attr(473, 1004)
		test_bag:print()
	end

	-- insert
	do
		-- insert delete row
		Log.debug("******* 9")
		test_bag:insert(
			{
				role_id = role_id,
				item_id = 1001,
				num = 132,
				sync_attr = 142,
				save_attr = 152,
				sync_save_attr = 162,
				tmp_attr = 172,
			})

		Log.debug("******* 10")
		test_bag:insert(
			{
				role_id = role_id,
				item_id = 1002,
				num = 232,
				sync_attr = 242,
				save_attr = 252,
				sync_save_attr = 262,
				tmp_attr = 272,
			})

		test_bag:print()
	end

	test_bag:sync_dirty()
	test_bag:save_dirty()

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
