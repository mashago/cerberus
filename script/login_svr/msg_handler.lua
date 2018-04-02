
local function handle_rpc_test(data, mailbox_id, msg_id)
	Log.debug("handle_rpc_test: data=%s", Util.table_to_string(data))

	local buff = data.buff

	-- 1. rpc to db
	-- 2. rpc to bridge
	-- 3. bridge rpc to gate
	-- 4. gate rpc to scene
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
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("handle_rpc_test rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
		return
	end
	Log.debug("handle_rpc_test: callback ret=%s", Util.table_to_string(ret))

	buff = ret.buff
	sum = ret.sum
	msg.buff = buff
	msg.sum = sum

	-- 2. get bridge
	local server_id = g_area_mgr:get_server_id(area_id)
	local status, ret = g_rpc_mgr:call_by_server_id(server_id, "bridge_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("handle_rpc_test rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
		return
	end
	Log.debug("handle_rpc_test: callback ret=%s", Util.table_to_string(ret))

	buff = ret.buff
	sum = ret.sum
	msg.result = ret.result
	msg.buff = buff
	msg.sum = sum

	Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
end


local function handle_rpc_nocb_test(data, mailbox_id, msg_id)
	Log.debug("handle_rpc_nocb_test: data=%s", Util.table_to_string(data))

	XXX_g_rpc_nocb_index = (XXX_g_rpc_nocb_index or 0) + 1
	local buff = data.buff
	local index = XXX_g_rpc_nocb_index

	-- rpc nocb to db
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	g_rpc_mgr:call_nocb_by_server_type(ServerType.DB, "db_rpc_nocb_test", rpc_data)

	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 2,
	}
	g_rpc_mgr:call_nocb_by_server_type(ServerType.DB, "db_rpc_nocb_test", rpc_data)

	-- rpc nocb to bridge
	local area_id = 1
	local server_id = g_area_mgr:get_server_id(area_id)
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	g_rpc_mgr:call_nocb_by_server_id(server_id, "bridge_rpc_nocb_test", rpc_data)
end

local function handle_rpc_mix_test(data, mailbox_id, msg_id)
	Log.debug("handle_rpc_mix_test: data=%s", Util.table_to_string(data))

	XXX_g_rpc_nocb_index = (XXX_g_rpc_nocb_index or 0) + 1
	local buff = data.buff
	local index = XXX_g_rpc_nocb_index

	local area_id = 1
	local sum = 0

	local msg =
	{
		result = ErrorCode.SUCCESS,
		buff = "",
		sum = 0,
	}

	-- rpc to db
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("handle_rpc_mix_test rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
		return
	end
	Log.debug("handle_rpc_mix_test: callback ret=%s", Util.table_to_string(ret))

	buff = ret.buff
	sum = ret.sum
	msg.buff = buff
	msg.sum = sum

	-- rpc nocb to db
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	g_rpc_mgr:call_nocb_by_server_type(ServerType.DB, "db_rpc_nocb_test", rpc_data)

	-- rpc to bridge
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = sum,
	}
	local server_id = g_area_mgr:get_server_id(area_id)
	local status, ret = g_rpc_mgr:call_by_server_id(server_id, "bridge_rpc_mix_test", rpc_data)
	if not status then
		Log.err("handle_rpc_mix_test rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
		return
	end
	Log.debug("handle_rpc_mix_test: callback ret=%s", Util.table_to_string(ret))

	buff = ret.buff
	sum = ret.sum
	msg.result = ret.result
	msg.buff = buff
	msg.sum = sum

	Net.send_msg(mailbox_id, MID.RPC_TEST_RET, msg)
end


------------------------------------------------------------------

local function handle_register_area(data, mailbox_id, msg_id)
	Log.debug("handle_register_area: data=%s", Util.table_to_string(data))

	local server_info = g_service_mgr:get_server_by_mailbox(mailbox_id)
	if not server_info then
		Log.warn("handle_register_area: unknow server mailbox_id=%d", mailbox_id)
	end
	server_info:print()

	local msg =
	{
		result = ErrorCode.SUCCESS
	}
	if not g_area_mgr:register_area(server_info._server_id, data.area_list) then
		Log.warn("handle_register_area: register_area duplicate %s %s", server_info._server_id, Util.table_to_string(data.area_list))
		msg.result = ErrorCode.REGISTER_AREA_DUPLICATE
		server_info:send_msg(MID.REGISTER_AREA_RET, msg)
		return
	end

	server_info:send_msg(MID.REGISTER_AREA_RET, msg)
end

------------------------------------------------------------------

local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.table_to_string(data))

	local msg =
	{
		result = ErrorCode.SUCCESS
	}

	local user = g_user_mgr:get_user_by_mailbox(mailbox_id)
	if user then
		Log.warn("handle_user_login duplicate login [%s]", data.username)
		msg.result = ErrorCode.USER_LOGIN_DUPLICATE_LOGIN
		Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
		return
	end

	-- core logic
	local username = data.username
	local password = data.password
	local channel_id = data.channel_id
	local rpc_data = 
	{
		username=username, 
		password=password, 
		channel_id=channel_id,
	}
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_user_login", rpc_data)
	if not status then
		Log.err("handle_user_login rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
		return
	end

	Log.debug("handle_user_login: callback ret=%s", Util.table_to_string(ret))

	-- check after rpc
	-- check connection
	local mailbox = Net.get_mailbox(mailbox_id)
	if not mailbox then
		Log.warn("handle_user_login: connect close username=%s", username)
		return
	end

	-- check result
	if ret.result ~= ErrorCode.SUCCESS then
		msg.result = ret.result
		Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
		return
	end

	-- check duplicate login
	local user = g_user_mgr:get_user_by_mailbox(mailbox_id)
	if user then
		Log.warn("handle_user_login duplicate login [%s]", data.username)
		msg.result = ErrorCode.USER_LOGIN_DUPLICATE_LOGIN
		Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
		return
	end
	--

	local user_id = ret.user_id
	Log.debug("handle_user_login: user_id=%d", user_id)

	local user = g_user_mgr:get_user_by_id(ret.user_id)
	if user then
		-- kick old connection, and change user mailbox
		Log.warn("handle_user_login login other place [%s]", data.username)
		msg.result = ErrorCode.USER_LOGIN_OTHER_PLACE
		user:send_msg(MID.USER_LOGIN_RET, msg)
		g_user_mgr:change_user_mailbox(user, mailbox_id)
	else
		-- create a user in memory with user_id
		local User = require "login_svr.user"
		user = User.new(mailbox_id, user_id, username, channel_id)
		if not g_user_mgr:add_user(user) then
			Log.warn("handle_user_login duplicate login2 [%s]", username)
			msg.result = ErrorCode.USER_LOGIN_DUPLICATE_LOGIN
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, msg)
			return
		end
	end

	msg.result = ErrorCode.SUCCESS
	user:send_msg(MID.USER_LOGIN_RET, msg)

end

local function handler_area_list_req(user, data, mailbox_id, msg_id)
	Log.debug("handler_area_list_req: data=%s", Util.table_to_string(data))

	local area_map = g_area_mgr._area_map
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
	Log.debug("handle_role_list_req: data=%s", Util.table_to_string(data))

	user:get_role_list()
	--[[
	local msg =
	{
		result = ErrorCode.SUCCESS,
		area_role_list = {},
	}

	-- get role list from user if exists
	-- rpc db to get role list, and save into user

	local function send_role_list()
		for area_id, role_list in pairs(user._role_map) do
			local node = {}
			node.area_id = area_id
			node.role_list = role_list
			table.insert(msg.area_role_list, node)
		end
		user:send_msg(MID.ROLE_LIST_RET, msg)
	end
	
	-- already get role list
	if user._role_map then
		send_role_list()
		return
	end

	-- first time get role list
	local rpc_data = 
	{
		table_name="user_role",
		fields={"role_id", "role_name, area_id"},
		conditions=
		{
			user_id=user._user_id, 
			is_delete=0,
		}
	}
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_login_select", rpc_data)
	if not status then
		Log.err("handle_role_list_req rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		user:send_msg(MID.ROLE_LIST_RET, msg)
		return
	end
	Log.debug("handle_role_list_req: callback ret=%s", Util.table_to_string(ret))

	if not user:is_ok() then
		return
	end

	if ret.result ~= ErrorCode.SUCCESS then
		msg.result = ret.result
		user:send_msg(MID.ROLE_LIST_RET, msg)
		return
	end

	if user._role_map then
		send_role_list()
		return
	end

	-- ok now
	-- save data into user role_list
	-- all data from db is string, must convert to number 
	user._role_map = {}
	
	for _, v in ipairs(ret.data) do
		
		local role_id = tonumber(v.role_id)
		local role_name = v.role_name
		local area_id = tonumber(v.area_id)

		user:add_role(area_id, role_id, role_name)
	end

	send_role_list()
	--]]
end

local function handle_create_role(user, data, mailbox_id, msg_id)
	Log.debug("handle_create_role: data=%s", Util.table_to_string(data))

	local area_id = data.area_id
	local role_name = data.role_name

	return user:create_role(area_id, role_name)

end

local function handle_delete_role(user, data, mailbox_id, msg_id)
	Log.debug("handle_delete_role: data=%s", Util.table_to_string(data))

	local area_id = data.area_id
	local role_id = data.role_id

	return user:delete_role(area_id, role_id)
end

local function handle_select_role(user, data, mailbox_id, msg_id)
	Log.debug("handle_select_role: data=%s", Util.table_to_string(data))

	local area_id = data.area_id
	local role_id = data.role_id

	return user:select_role(area_id, role_id)
end

local function register_msg_handler()

	-- for test
	Net.add_msg_handler(MID.RPC_TEST_REQ, handle_rpc_test)
	Net.add_msg_handler(MID.RPC_NOCB_TEST_REQ, handle_rpc_nocb_test)
	Net.add_msg_handler(MID.RPC_MIX_TEST_REQ, handle_rpc_mix_test)

	Net.add_msg_handler(MID.SHAKE_HAND_REQ, g_funcs.handle_shake_hand_req)
	Net.add_msg_handler(MID.SHAKE_HAND_RET, g_funcs.handle_shake_hand_ret)

	Net.add_msg_handler(MID.REGISTER_AREA_REQ, handle_register_area)

	Net.add_msg_handler(MID.USER_LOGIN_REQ, handle_user_login)
	Net.add_msg_handler(MID.AREA_LIST_REQ, handler_area_list_req)
	Net.add_msg_handler(MID.ROLE_LIST_REQ, handle_role_list_req)
	Net.add_msg_handler(MID.CREATE_ROLE_REQ, handle_create_role)
	Net.add_msg_handler(MID.DELETE_ROLE_REQ, handle_delete_role)
	Net.add_msg_handler(MID.SELECT_ROLE_REQ, handle_select_role)
end

register_msg_handler()
