
local Core = require "core"
local Log = require "log.logger"
local Util = require "util.util"
local Env = require "env"
local rpc_mgr = Core.rpc_mgr
local ErrorCode = ErrorCode

function rpc_mgr.gate_rpc_test(data)
	
	Log.debug("gate_rpc_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local sum = data.sum

	buff = buff .. "3"
	sum = sum + 1

	return rpc_mgr:ret({result = ErrorCode.SUCCESS, buff=buff, sum=sum})
end

local XXX_g_rpc_send_map = {}
function rpc_mgr.gate_rpc_send_test(data)
	Log.debug("gate_rpc_send_test: data=%s", Util.table_to_string(data))

	-- local buff = data.buff
	local index = data.index
	local sum = data.sum

	local last_sum = XXX_g_rpc_send_map[index]
	if not last_sum then
		XXX_g_rpc_send_map[index] = sum
		return
	end

	if sum < last_sum then
		Log.err("gate_rpc_send_test bug index=%d sum=%d last_sum=%d", index, sum, last_sum)
		return
	end

	XXX_g_rpc_send_map[index] = sum

end

---------------------------------------------------------

function rpc_mgr.gate_select_role(data)
	
	Log.debug("gate_select_role: data=%s", Util.table_to_string(data))

	local user_id = data.user_id
	local role_id = data.role_id
	-- local server_id = data.server_id
	local scene_id = data.scene_id
	local token = data.token
	
	local msg =
	{
		result = ErrorCode.SUCCESS,
		ip = "",
		port = 0,
	}

	if Env.user_mgr:get_user_by_id(user_id) then
		msg.result = ErrorCode.SYS_ERROR
		return rpc_mgr:ret(msg)
	end

	-- create user
	local User = require "gate_svr.user"
	local user = User.new(user_id, role_id, scene_id, token)
	Env.user_mgr:add_user(user)
	
	msg.result = ErrorCode.SUCCESS
	msg.ip = Core.server_conf._ip
	msg.port = Core.server_conf._port

	return rpc_mgr:ret(msg)
end

function rpc_mgr.gate_kick_role(data)
	local user_id = data.user_id
	-- local role_id = data.role_id
	local reason = data.reason

	local msg =
	{
		result = ErrorCode.SUCCESS,
		server_id = 0,
		scene_id = 0,
	}

	local user = Env.user_mgr:get_user_by_id(user_id)
	if user then
		Env.user_mgr:kick_user(user, reason)
		msg.server_id = user._scene_server_id
		msg.scene_id = user._scene_id
	end

	return rpc_mgr:ret(msg)
end

