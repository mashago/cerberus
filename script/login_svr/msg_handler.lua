local User = require "login_svr.user"

local function handle_register_area(data, mailbox_id, msg_id)
	Log.debug("handle_register_area: data=%s", Util.TableToString(data))

	local server_info = ServiceServer.get_server_by_mailbox(mailbox_id)
	if not server_info then
		Log.warn("handle_register_area: unknow server mailbox_id=%d", mailbox_id)
	end
	Log.debug("server_info=%s", Util.TableToString(server_info))

	if not AreaMgr.register_area(server_info.server_id, data.area_list) then
		Log.warn("handle_register_area: register_area duplicate %s %s", server_info.server_id, Util.TableToString(data.area_list))
		Net.send_msg(mailbox_id, MID.REGISTER_AREA_RET, ErrorCode.REGISTER_AREA_DUPLICATE)
		return
	end

	Net.send_msg(mailbox_id, MID.REGISTER_AREA_RET, ErrorCode.SUCCESS)
end

local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))

	local func = function(mailbox_id, data)
		local user = UserMgr.get_user_by_mailbox(mailbox_id)
		if user then
			Log.warn("handle_user_login duplicate login [%s]", username)
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.USER_LOGIN_DUPLICATE_LOGIN)
			return
		end

		local server = ServiceClient.get_server_by_type(ServerType.DB)
		if not server then
			Log.err("handle_user_login no db server")
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.USER_LOGIN_FAIL)
			return
		end

		local username = data.username
		local password = data.password
		local channel_id = data.channel_id
		local rpc_data = {username=username, password=password, channel_id=channel_id}

		local status, result = RpcMgr.call(server, "db_user_login", rpc_data)
		if not status then
			Log.err("handle_user_login rpc call fail")
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.SYS_ERROR)
			return
		end

		Log.debug("handle_user_login: callback result=%s", Util.TableToString(result))

		-- check client mailbox_id is still legal, after rpc
		local mailbox = Net.get_mailbox(mailbox_id)
		if not mailbox then
			Log.warn("handle_user_login: user offline username=%s", username)
			return
		end

		if result.result ~= ErrorCode.SUCCESS then
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, result.result)
			return
		end

		-- create a user in memory with user_id
		local user_id = result.user_id
		Log.debug("handle_user_login: user_id=%d", user_id)

		local user = User:new(mailbox_id, user_id, username, channel_id)
		if not UserMgr.add_user(user) then
			Log.warn("handle_user_login duplicate login2 [%s]", username)
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.USER_LOGIN_DUPLICATE_LOGIN)
			return
		end

		Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.SUCCESS)
	end
	RpcMgr.run(func, mailbox_id, data)

end

local function handler_area_list_req(user, data, mailbox_id, msg_id)
	Log.debug("handler_area_list_req: data=%s", Util.TableToString(data))

	local area_map = AreaMgr._area_map
	local ret = {}
	for k, v in pairs(area_map) do
		table.insert(ret, {k, "qwerty"})
	end

	user:send_msg(MID.AREA_LIST_RET, ret)
end

local function handle_create_role(data, mailbox_id, msg_id)
	Log.debug("handle_create_role: data=%s", Util.TableToString(data))

	local func = function(mailbox_id, role_name)

		local area_id = 400001 -- TODO read from client
		local role_id = math.random(10000)

		local server = ServiceServer.get_server_by_scene(area_id)
		if not server then
			Log.err("handle_create_role no bridge server")
			Net.send_msg(mailbox_id, MID.CREATE_ROLE_RET, ErrorCode.CREATE_ROLE_FAIL)
			return
		end

		local status, result = RpcMgr.call(server, "bridge_create_role", {role_id=role_id, role_name=role_name})
		if not status then
			Log.err("handle_create_role rpc call fail")
			Net.send_msg(mailbox_id, MID.CREATE_ROLE_RET, ErrorCode.CREATE_ROLE_FAIL)
			return
		end

		Log.debug("handle_create_role: callback result=%s", Util.TableToString(result))

		-- TODO check mailbox_id is still legal, after rpc
		Net.send_msg(mailbox_id, MID.CREATE_ROLE_RET, result.result, result.role_id or 0)
	end
	RpcMgr.run(func, mailbox_id, data.role_name)

end

local function handle_rpc_test(data, mailbox_id, msg_id)
	Log.debug("handle_rpc_test: data=%s", Util.TableToString(data))

	local func = function(mailbox_id, buff)

		-- 1. rpc to db
		-- 2. rpc to bridge
		-- 3. bridge rpc to router
		-- 4. router rpc to scene
		-- 5. bridge rpc to scene

		local channel_id = 400001
		local sum = 0

		-- 1. rpc to db
		local server = ServiceClient.get_server_by_type(ServerType.DB)
		if not server then
			Log.err("handle_user_login no db server")
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.USER_LOGIN_FAIL)
			return
		end

		local status, result = RpcMgr.call(server, "db_rpc_test", {buff=buff, sum=sum})
		if not status then
			Log.err("handle_user_login rpc call fail")
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.USER_LOGIN_FAIL)
			return
		end
		Log.debug("handle_rpc_test: callback result=%s", Util.TableToString(result))
		buff = result.buff
		sum = result.sum

		-- 2. rpc to bridge
		local server = ServiceServer.get_server_by_scene(channel_id)
		if not server then
			Log.err("handle_rpc_test no bridge server")
			Net.send_msg(mailbox_id, MID.RPC_TEST_RET, ErrorCode.SYS_ERROR, buff, sum)
			return
		end
		local status, result = RpcMgr.call(server, "bridge_rpc_test", {buff=buff, sum=sum})
		if not status then
			Log.err("handle_rpc_test rpc call fail")
			Net.send_msg(mailbox_id, MID.RPC_TEST_RET, ErrorCode.SYS_ERROR, buff, sum)
			return
		end
		Log.debug("handle_rpc_test: callback result=%s", Util.TableToString(result))
		buff = result.buff
		sum = result.sum

		Net.send_msg(mailbox_id, MID.RPC_TEST_RET, result.result, result.buff, result.sum)
	end
	RpcMgr.run(func, mailbox_id, data.buff)

end

function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, g_funcs.handle_register_server)
	Net.add_msg_handler(MID.REGISTER_AREA_REQ, handle_register_area)

	Net.add_msg_handler(MID.USER_LOGIN_REQ, handle_user_login)
	Net.add_msg_handler(MID.AREA_LIST_REQ, handler_area_list_req)

	Net.add_msg_handler(MID.CREATE_ROLE_REQ, handle_create_role)
	Net.add_msg_handler(MID.RPC_TEST_REQ, handle_rpc_test)
end
