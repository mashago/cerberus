
local Core = require "core"
-- [
local Log = require "core.log.logger"
local Util = require "core.util.util"
local Env = require "env"

local rpc_mgr = Core.rpc_mgr
local ServerType = ServerType
local ErrorCode = ErrorCode


function rpc_mgr.bridge_rpc_test(data)
	
	Log.debug("bridge_rpc_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local sum = data.sum

	buff = buff .. "2"
	sum = sum + 1

	-- rpc to gate
	local status, ret = rpc_mgr:call_by_server_type(ServerType.GATE, "gate_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("bridge_rpc_test rpc call fail")
		return rpc_mgr:ret({result = ErrorCode.RPC_FAIL, buff=buff, sum=sum})
	end
	Log.debug("bridge_rpc_test: callback ret=%s", Util.table_to_string(ret))
	buff = ret.buff
	sum = ret.sum

	-- rpc to scene
	status, ret = rpc_mgr:call_by_server_type(ServerType.SCENE, "scene_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("bridge_rpc_test rpc call fail")
		return rpc_mgr:ret({result = ErrorCode.RPC_FAIL, buff=buff, sum=sum})
	end
	Log.debug("bridge_rpc_test: callback ret=%s", Util.table_to_string(ret))
	buff = ret.buff
	sum = ret.sum

	return rpc_mgr:ret({result = ErrorCode.SUCCESS, buff=buff, sum=sum})
end

function rpc_mgr.bridge_rpc_send_test(data)
	Log.debug("bridge_rpc_send_test: data=%s", Util.table_to_string(data))


	local buff = data.buff
	local index = data.index

	-- rpc send to gate
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	rpc_mgr:send_by_server_type(ServerType.GATE, "gate_rpc_send_test", rpc_data)

	rpc_data =
	{
		buff = buff,
		index = index,
		sum = 2,
	}
	rpc_mgr:send_by_server_type(ServerType.GATE, "gate_rpc_send_test", rpc_data)

	-- rpc send to scene
	local server_info = Core.server_mgr:get_server_by_type(ServerType.SCENE)
	if not server_info then
		Log.warn("bridge_rpc_send_test server_info nil")
		return
	end
	local server_id = server_info._server_id

	rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	rpc_mgr:send_by_server_id(server_id, "scene_rpc_send_test", rpc_data)

	rpc_data =
	{
		buff = buff,
		index = index,
		sum = 2,
	}
	rpc_mgr:send_by_server_id(server_id, "scene_rpc_send_test", rpc_data)

end

function rpc_mgr.bridge_rpc_mix_test(data)
	
	Log.debug("bridge_rpc_mix_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local index = data.index
	local sum = data.sum

	buff = buff .. "2"
	sum = sum + 1

	-- rpc to gate
	local status, ret = rpc_mgr:call_by_server_type(ServerType.GATE, "gate_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("bridge_rpc_mix_test rpc call fail")
		return rpc_mgr:ret({result = ErrorCode.RPC_FAIL, buff=buff, sum=sum})
	end
	Log.debug("bridge_rpc_mix_test: callback ret=%s", Util.table_to_string(ret))
	buff = ret.buff
	sum = ret.sum

	-- rpc send gate
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	rpc_mgr:send_by_server_type(ServerType.GATE, "gate_rpc_send_test", rpc_data)

	rpc_data =
	{
		buff = buff,
		index = index,
		sum = 2,
	}
	rpc_mgr:send_by_server_type(ServerType.GATE, "gate_rpc_send_test", rpc_data)


	local server_info = Core.server_mgr:get_server_by_type(ServerType.SCENE)
	if not server_info then
		Log.warn("bridge_rpc_mix_test server_info nil")
		return
	end
	local server_id = server_info._server_id

	-- rpc send to scene
	rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	rpc_mgr:send_by_server_id(server_id, "scene_rpc_send_test", rpc_data)

	rpc_data =
	{
		buff = buff,
		index = index,
		sum = 2,
	}
	rpc_mgr:send_by_server_id(server_id, "scene_rpc_send_test", rpc_data)
	
	-- rpc to scene
	status, ret = rpc_mgr:call_by_server_id(server_id, "scene_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("bridge_rpc_mix_test rpc call fail")
		return rpc_mgr:ret({result = ErrorCode.RPC_FAIL, buff=buff, sum=sum})
	end
	Log.debug("bridge_rpc_mix_test: callback ret=%s", Util.table_to_string(ret))
	buff = ret.buff
	sum = ret.sum

	return rpc_mgr:ret({result = ErrorCode.SUCCESS, buff=buff, sum=sum})
end
-- ]

-----------------------------------------------------------

function rpc_mgr.bridge_sync_gate_conn_num(data, mailbox_id)
	-- Log.debug("bridge_sync_gate_conn_num data=%s", Util.table_to_string(data))
	
	local server_info = Core.server_mgr:get_server_by_mailbox(mailbox_id)
	if not server_info then
		Log.err("bridge_sync_gate_conn_num not server")
		return
	end

	local server_id = server_info._server_id
	local server_type = server_info._server_type
	if server_type ~= ServerType.GATE then
		Log.err("bridge_sync_gate_conn_num not gate server server_id=%d server_type=%d", server_id, server_type)
		return
	end

	Env.common_mgr:sync_gate_conn_num(server_id, data.num)
end

-----------------------------------------------------------

function rpc_mgr.bridge_create_role(data)
	
	Log.debug("bridge_create_role data=%s", Util.table_to_string(data))

	return rpc_mgr:ret(Env.common_mgr:rpc_create_role(data))
end

function rpc_mgr.bridge_delete_role(data)
	
	Log.debug("bridge_delete_role: data=%s", Util.table_to_string(data))

	local user_id = data.user_id
	local role_id = data.role_id

	return rpc_mgr:ret(Env.common_mgr:rpc_delete_role(user_id, role_id))
end

function rpc_mgr.bridge_select_role(data)
	
	Log.debug("bridge_select_role: data=%s", Util.table_to_string(data))

	local user_id = data.user_id
	local role_id = data.role_id

	return rpc_mgr:ret(Env.common_mgr:rpc_select_role(user_id, role_id))
end

function rpc_mgr.bridge_user_offline(data)

	Log.debug("bridge_user_offline: data=%s", Util.table_to_string(data))

	local user_id = data.user_id

	return rpc_mgr:ret(Env.common_mgr:rpc_user_offline(user_id))
end
