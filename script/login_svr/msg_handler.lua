
local Core = require "core"
local g_msg_handler = require "core.global.msg_handler"
local Log = require "core.log.logger"
local Util = require "core.util.util"
local ErrorCode = ErrorCode
local ServerType = ServerType
local MID = MID
local Env = require "env"

function g_msg_handler.c2s_rpc_test_req(data, mailbox_id, msg_id)
	Log.debug("c2s_rpc_test_req: data=%s", Util.table_to_string(data))

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
	local status, ret = Core.rpc_mgr:call_by_server_type(ServerType.DB, "db_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("c2s_rpc_test_req rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		Core.net_mgr:send_msg(mailbox_id, MID.s2c_rpc_test_ret, msg)
		return
	end
	Log.debug("c2s_rpc_test_req: callback ret=%s", Util.table_to_string(ret))

	buff = ret.buff
	sum = ret.sum
	msg.buff = buff
	msg.sum = sum

	-- 2. get bridge
	local server_id = Env.area_mgr:get_server_id(area_id)
	status, ret = Core.rpc_mgr:call_by_server_id(server_id, "bridge_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("c2s_rpc_test_req rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		Core.net_mgr:send_msg(mailbox_id, MID.s2c_rpc_test_ret, msg)
		return
	end
	Log.debug("c2s_rpc_test_req: callback ret=%s", Util.table_to_string(ret))

	buff = ret.buff
	sum = ret.sum
	msg.result = ret.result
	msg.buff = buff
	msg.sum = sum

	Core.net_mgr:send_msg(mailbox_id, MID.s2c_rpc_test_ret, msg)
end


local XXX_g_rpc_send_index = 0
function g_msg_handler.c2s_rpc_send_test_req(data, mailbox_id, msg_id)
	Log.debug("c2s_rpc_send_test_req: data=%s", Util.table_to_string(data))

	XXX_g_rpc_send_index = XXX_g_rpc_send_index + 1
	local buff = data.buff
	local index = XXX_g_rpc_send_index

	-- rpc send to db
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	Core.rpc_mgr:send_by_server_type(ServerType.DB, "db_rpc_send_test", rpc_data)

	rpc_data =
	{
		buff = buff,
		index = index,
		sum = 2,
	}
	Core.rpc_mgr:send_by_server_type(ServerType.DB, "db_rpc_send_test", rpc_data)

	-- rpc send to bridge
	local area_id = 1
	local server_id = Env.area_mgr:get_server_id(area_id)
	rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	Core.rpc_mgr:send_by_server_id(server_id, "bridge_rpc_send_test", rpc_data)
end

function g_msg_handler.c2s_rpc_mix_test_req(data, mailbox_id, msg_id)
	Log.debug("c2s_rpc_mix_test_req: data=%s", Util.table_to_string(data))

	XXX_g_rpc_send_index = XXX_g_rpc_send_index + 1
	local buff = data.buff
	local index = XXX_g_rpc_send_index

	local area_id = 1
	local sum = 0

	local msg =
	{
		result = ErrorCode.SUCCESS,
		buff = "",
		sum = 0,
	}

	-- rpc to db
	local status, ret = Core.rpc_mgr:call_by_server_type(ServerType.DB, "db_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("c2s_rpc_mix_test_req rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		Core.net_mgr:send_msg(mailbox_id, MID.s2c_rpc_test_ret, msg)
		return
	end
	Log.debug("c2s_rpc_mix_test_req: callback ret=%s", Util.table_to_string(ret))

	buff = ret.buff
	sum = ret.sum
	msg.buff = buff
	msg.sum = sum

	-- rpc send to db
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	Core.rpc_mgr:send_by_server_type(ServerType.DB, "db_rpc_send_test", rpc_data)

	-- rpc to bridge
	rpc_data =
	{
		buff = buff,
		index = index,
		sum = sum,
	}
	local server_id = Env.area_mgr:get_server_id(area_id)
	status, ret = Core.rpc_mgr:call_by_server_id(server_id, "bridge_rpc_mix_test", rpc_data)
	if not status then
		Log.err("c2s_rpc_mix_test_req rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		Core.net_mgr:send_msg(mailbox_id, MID.s2c_rpc_test_ret, msg)
		return
	end
	Log.debug("c2s_rpc_mix_test_req: callback ret=%s", Util.table_to_string(ret))

	buff = ret.buff
	sum = ret.sum
	msg.result = ret.result
	msg.buff = buff
	msg.sum = sum

	Core.net_mgr:send_msg(mailbox_id, MID.s2c_rpc_test_ret, msg)
end


------------------------------------------------------------------

function g_msg_handler.s2s_register_area_req(data, mailbox_id, msg_id)
	Log.debug("s2s_register_area_req: data=%s", Util.table_to_string(data))

	local server_info = Core.server_mgr:get_server_by_mailbox(mailbox_id)
	if not server_info then
		Log.warn("s2s_register_area_req: unknow server mailbox_id=%d", mailbox_id)
	end
	server_info:print()

	local msg =
	{
		result = ErrorCode.SUCCESS
	}
	if not Env.area_mgr:register_area(server_info._server_id, data.area_list) then
		Log.warn("s2s_register_area_req: register_area duplicate %s %s"
		, server_info._server_id, Util.table_to_string(data.area_list))
		msg.result = ErrorCode.REGISTER_AREA_DUPLICATE
		server_info:send_msg(MID.s2s_register_area_ret, msg)
		return
	end

	server_info:send_msg(MID.s2s_register_area_ret, msg)
end

------------------------------------------------------------------

local XXX_DEBUG_TEST_LOGINX = false
function g_msg_handler.c2s_user_login_req(data, mailbox_id, msg_id)
	Log.debug("c2s_user_login_req: data=%s", Util.table_to_string(data))
	local user_mgr = Env.user_mgr

	local msg =
	{
		result = ErrorCode.SUCCESS
	}

	local user = user_mgr:get_user_by_mailbox(mailbox_id)
	if user then
		Log.warn("c2s_user_login_req duplicate login [%s]", data.username)
		msg.result = ErrorCode.USER_LOGIN_DUPLICATE_LOGIN
		Core.net_mgr:send_msg(mailbox_id, MID.s2c_user_login_ret, msg)
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
	local status, ret = Core.rpc_mgr:call_by_server_type(ServerType.DB, "db_user_login", rpc_data)
	if not status then
		Log.err("c2s_user_login_req rpc call fail")
		msg.result = ErrorCode.SYS_ERROR
		Core.net_mgr:send_msg(mailbox_id, MID.s2c_user_login_ret, msg)
		return
	end

	Log.debug("c2s_user_login_req: callback ret=%s", Util.table_to_string(ret))

	-- check after rpc
	-- check connection
	local mailbox = Core.net_mgr:get_mailbox(mailbox_id)
	if not mailbox then
		Log.warn("c2s_user_login_req: connect close username=%s", username)
		return
	end

	-- check result
	if ret.result ~= ErrorCode.SUCCESS then
		msg.result = ret.result
		Core.net_mgr:send_msg(mailbox_id, MID.s2c_user_login_ret, msg)
		return
	end

	-- check duplicate login
	user = user_mgr:get_user_by_mailbox(mailbox_id)
	if user then
		Log.warn("c2s_user_login_req duplicate login [%s]", data.username)
		msg.result = ErrorCode.USER_LOGIN_DUPLICATE_LOGIN
		Core.net_mgr:send_msg(mailbox_id, MID.s2c_user_login_ret, msg)
		return
	end

	local user_id = ret.user_id
	Log.debug("c2s_user_login_req: user_id=%d", user_id)

	if XXX_DEBUG_TEST_LOGINX then
		Core.net_mgr:send_msg(mailbox_id, MID.s2c_user_login_ret, msg)
		return
	end

	user = user_mgr:get_user_by_id(user_id)
	if user then
		-- kick old connection, and change user mailbox
		Log.warn("c2s_user_login_req login other place [%s]", data.username)
		local msg2 =
		{
			reason = ErrorCode.USER_LOGIN_OTHER_PLACE,
		}
		user:send_msg(MID.s2c_user_kick, msg2)
		user_mgr:change_user_mailbox(user, mailbox_id)
	else
		-- create a user in memory with user_id
		local User = require "login_svr.user"
		user = User.new(mailbox_id, user_id, username, channel_id)
		if not user_mgr:add_user(user) then
			Log.warn("c2s_user_login_req duplicate login2 [%s]", username)
			msg.result = ErrorCode.USER_LOGIN_DUPLICATE_LOGIN
			Core.net_mgr:send_msg(mailbox_id, MID.s2c_user_login_ret, msg)
			return
		end
	end

	msg.result = ErrorCode.SUCCESS
	user:send_msg(MID.s2c_user_login_ret, msg)

end

function g_msg_handler.c2s_area_list_req(user, data, mailbox_id, msg_id)
	Log.debug("c2s_area_list_req: data=%s", Util.table_to_string(data))

	local area_map = Env.area_mgr._area_map
	local area_list = {}
	for k in pairs(area_map) do
		table.insert(area_list, {area_id=k, area_name="qwerty"})
	end
	local msg =
	{
		area_list = area_list
	}

	user:send_msg(MID.s2c_area_list_ret, msg)
end

function g_msg_handler.c2s_role_list_req(user, data, mailbox_id, msg_id)
	Log.debug("c2s_role_list_req: data=%s", Util.table_to_string(data))

	return user:get_role_list()
end

function g_msg_handler.c2s_create_role_req(user, data, mailbox_id, msg_id)
	Log.debug("c2s_create_role_req: data=%s", Util.table_to_string(data))

	local area_id = data.area_id
	local role_name = data.role_name

	return user:create_role(area_id, role_name)
end

function g_msg_handler.c2s_delete_role_req(user, data, mailbox_id, msg_id)
	Log.debug("c2s_delete_role_req: data=%s", Util.table_to_string(data))

	local area_id = data.area_id
	local role_id = data.role_id

	return user:delete_role(area_id, role_id)
end

function g_msg_handler.c2s_select_role_req(user, data, mailbox_id, msg_id)
	Log.debug("c2s_select_role_req: data=%s", Util.table_to_string(data))

	local area_id = data.area_id
	local role_id = data.role_id

	return user:select_role(area_id, role_id)
end
