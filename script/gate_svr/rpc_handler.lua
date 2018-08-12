
local g_rpc_mgr = g_rpc_mgr
local Log = Log
local Util = Util
local ErrorCode = ErrorCode
local g_server_conf = g_server_conf

function g_rpc_mgr.gate_rpc_test(data)
	
	Log.debug("gate_rpc_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local sum = data.sum

	buff = buff .. "3"
	sum = sum + 1

	return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
end

local XXX_g_rpc_nocb_map = XXX_g_rpc_nocb_map or {}
function g_rpc_mgr.gate_rpc_nocb_test(data)
	Log.debug("gate_rpc_nocb_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local index = data.index
	local sum = data.sum

	local last_sum = XXX_g_rpc_nocb_map[index]
	if not last_sum then
		XXX_g_rpc_nocb_map[index] = sum
		return
	end

	if sum < last_sum then
		Log.err("gate_rpc_nocb_test bug index=%d sum=%d last_sum=%d", index, sum, last_sum)
		return
	end

	XXX_g_rpc_nocb_map[index] = sum

end

---------------------------------------------------------

function g_rpc_mgr.gate_select_role(data)
	
	Log.debug("gate_select_role: data=%s", Util.table_to_string(data))
	local g_user_mgr = g_user_mgr

	local user_id = data.user_id
	local role_id = data.role_id
	local server_id = data.server_id
	local scene_id = data.scene_id
	local token = data.token
	
	local msg =
	{
		result = ErrorCode.SUCCESS,
		ip = "",
		port = 0,
	}

	if g_user_mgr:get_user_by_id(user_id) then
		msg.result = ErrorCode.SYS_ERROR
		return msg
	end

	-- create user
	local User = require "gate_svr.user"
	local user = User.new(user_id, role_id, scene_id, token)
	g_user_mgr:add_user(user)
	
	msg.result = ErrorCode.SUCCESS
	msg.ip = g_server_conf._ip
	msg.port = g_server_conf._port

	return msg
end

function g_rpc_mgr.gate_kick_role(data)
	local g_user_mgr = g_user_mgr
	local user_id = data.user_id
	local role_id = data.role_id
	local reason = data.reason

	local msg =
	{
		result = ErrorCode.SUCCESS,
		server_id = 0,
		scene_id = 0,
	}

	local user = g_user_mgr:get_user_by_id(user_id)
	if user then
		g_user_mgr:kick_user(user, reason)
		msg.server_id = user._scene_server_id
		msg.scene_id = user._scene_id
	end

	return msg
end

