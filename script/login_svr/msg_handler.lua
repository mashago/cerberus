local User = require "login_svr.user"

local function handle_rpc_test(data, mailbox_id, msg_id)
	Log.debug("handle_rpc_test: data=%s", Util.TableToString(data))

	local func = function(mailbox_id, buff)

		-- 1. rpc to db
		-- 2. rpc to bridge
		-- 3. bridge rpc to router
		-- 4. router rpc to scene
		-- 5. bridge rpc to scene

		local area_id = 1
		local sum = 0

		local msg =
		{
			result = ErrorCode.SUCCESS,
			buff = "",
			sum = 0,
		}

		-- 1. rpc to db
		local server_info = ServiceMgr.get_server_by_type(ServerType.DB)
		if not server_info then
			Log.err("handle_user_login no db server_info")
			msg.result = ErrorCode.SYS_ERROR
			Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
			return
		end

		local status, result = RpcMgr.call(server_info, "db_rpc_test", {buff=buff, sum=sum})
		if not status then
			Log.err("handle_user_login rpc call fail")
			msg.result = ErrorCode.SYS_ERROR
			Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
			return
		end
		Log.debug("handle_rpc_test: callback result=%s", Util.TableToString(result))

		buff = result.buff
		sum = result.sum
		msg.buff = buff
		msg.sum = sum

		-- 2. get bridge
		local server_id = AreaMgr.get_server_id(area_id)
		local server_info = ServiceMgr.get_server_by_id(server_id)
		if not server_info then
			Log.err("handle_rpc_test no bridge server_info")
			msg.result = ErrorCode.SYS_ERROR
			Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
			return
		end

		-- 3. rpc to bridge
		local status, result = RpcMgr.call(server_info, "bridge_rpc_test", {buff=buff, sum=sum})
		if not status then
			Log.err("handle_rpc_test rpc call fail")
			msg.result = ErrorCode.SYS_ERROR
			Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
			return
		end
		Log.debug("handle_rpc_test: callback result=%s", Util.TableToString(result))

		buff = result.buff
		sum = result.sum
		msg.result = result.result
		msg.buff = buff
		msg.sum = sum

		Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
	end
	RpcMgr.run(func, mailbox_id, data.buff)
end

------------------------------------------------------------------

local function handle_register_area(data, mailbox_id, msg_id)
	Log.debug("handle_register_area: data=%s", Util.TableToString(data))

	local server_info = ServiceMgr.get_server_by_mailbox(mailbox_id)
	if not server_info then
		Log.warn("handle_register_area: unknow server mailbox_id=%d", mailbox_id)
	end
	server_info:print()

	local msg =
	{
		result = ErrorCode.SUCCESS
	}
	if not AreaMgr.register_area(server_info._server_id, data.area_list) then
		Log.warn("handle_register_area: register_area duplicate %s %s", server_info._server_id, Util.TableToString(data.area_list))
		msg.result = ErrorCode.REGISTER_AREA_DUPLICATE
		server_info:send_msg(MID.REGISTER_AREA_RET, msg)
		return
	end

	server_info:send_msg(MID.REGISTER_AREA_RET, msg)
end

local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))

	local func = function(mailbox_id, data)
		local msg =
		{
			result = ErrorCode.SUCCESS
		}

		local user = UserMgr.get_user_by_mailbox(mailbox_id)
		if user then
			Log.warn("handle_user_login duplicate login [%s]", data.username)
			msg.result = ErrorCode.USER_LOGIN_DUPLICATE_LOGIN
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
			return
		end

		local server_info = ServiceMgr.get_server_by_type(ServerType.DB)
		if not server_info then
			Log.err("handle_user_login no db server_info")
			msg.result = ErrorCode.USER_LOGIN_FAIL
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
			return
		end

		-- core logic
		local username = data.username
		local password = data.password
		local channel_id = data.channel_id
		local rpc_data = {username=username, password=password, channel_id=channel_id}

		local status, result = RpcMgr.call(server_info, "db_user_login", rpc_data)
		if not status then
			Log.err("handle_user_login rpc call fail")
			msg.result = ErrorCode.SYS_ERROR
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
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
			msg.result = result.result
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
			return
		end

		-- ok now
		-- create a user in memory with user_id
		local user_id = result.user_id
		Log.debug("handle_user_login: user_id=%d", user_id)

		local user = User:new(mailbox_id, user_id, username, channel_id)
		if not UserMgr.add_user(user) then
			Log.warn("handle_user_login duplicate login2 [%s]", username)
			msg.result = ErrorCode.USER_LOGIN_DUPLICATE_LOGIN
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
			return
		end

		msg.result = ErrorCode.SUCCESS
		Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
	end
	RpcMgr.run(func, mailbox_id, data)

end

local function handler_area_list_req(user, data, mailbox_id, msg_id)
	Log.debug("handler_area_list_req: data=%s", Util.TableToString(data))

	local area_map = AreaMgr._area_map
	local area_list = {}
	for k, v in pairs(area_map) do
		table.insert(area_list, {area_id=k, area_name="qwerty"})
	end
	local msg =
	{
		area_list = area_list
	}

	user:send_msg(MID.AREA_LIST_RET, msg)
end

local function handle_role_list_req(user, data, mailbox_id, msg_id)
	Log.debug("handle_role_list_req: data=%s", Util.TableToString(data))

	local msg =
	{
		result = ErrorCode.SUCCESS,
		area_id = data.area_id,
		role_list = {},
	}

	-- already get role list
	if user._role_map[data.area_id] then
		for k, v in ipairs(user._role_map[data.area_id]) do
			table.insert(msg.role_list, v)
		end

		user:send_msg(MID.ROLE_LIST_RET, msg)
		return
	end

	-- first time get role list
	local func = function(user, data)

		local area_id = data.area_id
		local msg =
		{
			result = ErrorCode.SUCCESS,
			area_id = area_id,
			role_list = {},
		}

		local server_info = ServiceMgr.get_server_by_type(ServerType.DB)
		if not server_info then
			Log.err("handle_role_list_req no db server_info")
			msg.result = ErrorCode.SYS_ERROR
			user:send_msg(MID.ROLE_LIST_RET, msg)
			return
		end

		local rpc_data = 
		{
			user_id=user._user_id, 
			area_id=area_id, 
		}
		local status, result = RpcMgr.call(server_info, "db_role_list", rpc_data)
		if not status then
			Log.err("handle_role_list_req rpc call fail")
			msg.result = ErrorCode.SYS_ERROR
			user:send_msg(MID.ROLE_LIST_RET, msg)
			return
		end
		Log.debug("handle_role_list_req: callback result=%s", Util.TableToString(result))

		if result.result ~= ErrorCode.SUCCESS then
			msg.result = result.result
			user:send_msg(MID.ROLE_LIST_RET, msg)
			return
		end

		-- ok now
		-- save role_list into user
		user._role_map[area_id] = result.role_list
		msg.role_list = result.role_list

		user:send_msg(MID.ROLE_LIST_RET, msg)
	end
	RpcMgr.run(func, user, data)
end

local function handle_create_role(user, data, mailbox_id, msg_id)
	Log.debug("handle_create_role: data=%s", Util.TableToString(data))

	local func = function(user, data)

		local area_id = data.area_id
		local role_name = data.role_name

		local msg =
		{
			result = ErrorCode.SUCCESS,
			role_id = 0,
		}

		-- 1. rpc to db create role
		-- 2. rpc to area bridge

		local server_id = AreaMgr.get_server_id(area_id)
		if server_id < 0 then
			Log.warn("handle_create_role no such area %d", area_id)
			msg.result = ErrorCode.CREATE_ROLE_FAIL
			user:send_msg(MID.CREATE_ROLE_RET, msg)
			return
		end

		local server_info = ServiceMgr.get_server_by_type(ServerType.DB)
		if not server_info then
			Log.err("handle_create_role no db server_info")
			msg.result = ErrorCode.CREATE_ROLE_FAIL
			user:send_msg(MID.CREATE_ROLE_RET, msg)
			return
		end

		-- 1. rpc to db create role
		local username = data.username
		local password = data.password
		local channel_id = data.channel_id
		local rpc_data = 
		{
			user_id=user._user_id, 
			area_id=area_id, 
			role_name=role_name
		}
		local status, result = RpcMgr.call(server_info, "db_create_role", rpc_data)
		if not status then
			Log.err("handle_create_role rpc call fail")
			msg.result = ErrorCode.SYS_ERROR
			user:send_msg(MID.CREATE_ROLE_RET, msg)
			return
		end
		Log.debug("handle_create_role: callback result=%s", Util.TableToString(result))

		if result.result ~= ErrorCode.SUCCESS then
			msg.result = result.result
			user:send_msg(MID.CREATE_ROLE_RET, msg)
			return
		end

		local role_id = result.role_id
		msg.role_id = role_id

		-- 2. rpc to area bridge
		local server_id = AreaMgr.get_server_id(area_id)
		local server_info = ServiceMgr.get_server_by_id(server_id)
		if not server_info then
			-- area not exists, TODO should delete role in db
			Log.err("handle_create_role no bridge server_info2 %d", area_id)
			msg.result = ErrorCode.SYS_ERROR
			user:send_msg(MID.CREATE_ROLE_RET, msg)
			return
		end

		local rpc_data = 
		{
			user_id=user._user_id, 
			area_id=area_id, 
			role_id=role_id,
			role_name=role_name,
		}
		local status, result = RpcMgr.call(server_info, "bridge_create_role", rpc_data)
		if not status then
			Log.err("handle_create_role rpc call fail")
			msg.result = ErrorCode.CREATE_ROLE_FAIL
			user:send_msg(MID.CREATE_ROLE_RET, msg)
			return
		end
		Log.debug("handle_create_role: callback result2=%s", Util.TableToString(result))

		-- ok now

		user:send_msg(MID.CREATE_ROLE_RET, msg)
	end
	RpcMgr.run(func, user, data)

end

function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, g_funcs.handle_register_server)
	Net.add_msg_handler(MID.REGISTER_AREA_REQ, handle_register_area)

	Net.add_msg_handler(MID.USER_LOGIN_REQ, handle_user_login)
	Net.add_msg_handler(MID.AREA_LIST_REQ, handler_area_list_req)
	Net.add_msg_handler(MID.ROLE_LIST_REQ, handle_role_list_req)
	Net.add_msg_handler(MID.CREATE_ROLE_REQ, handle_create_role)

	Net.add_msg_handler(MID.RPC_TEST_REQ, handle_rpc_test)
end
