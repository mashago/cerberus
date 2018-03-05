
-- [
local function bridge_rpc_test(data)
	
	Log.debug("bridge_rpc_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local sum = data.sum

	buff = buff .. "2"
	sum = sum + 1

	-- rpc to gate
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.GATE, "gate_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("bridge_rpc_test rpc call fail")
		return {result = ErrorCode.RPC_FAIL, buff=buff, sum=sum}
	end
	Log.debug("bridge_rpc_test: callback ret=%s", Util.table_to_string(ret))
	buff = ret.buff
	sum = ret.sum

	-- rpc to scene
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.SCENE, "scene_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("bridge_rpc_test rpc call fail")
		return {result = ErrorCode.RPC_FAIL, buff=buff, sum=sum}
	end
	Log.debug("bridge_rpc_test: callback ret=%s", Util.table_to_string(ret))
	buff = ret.buff
	sum = ret.sum

	return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
end

local function bridge_rpc_nocb_test(data)
	Log.debug("bridge_rpc_nocb_test: data=%s", Util.table_to_string(data))


	local buff = data.buff
	local index = data.index

	-- rpc nocb to gate
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	g_rpc_mgr:call_nocb_by_server_type(ServerType.GATE, "gate_rpc_nocb_test", rpc_data)

	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 2,
	}
	g_rpc_mgr:call_nocb_by_server_type(ServerType.GATE, "gate_rpc_nocb_test", rpc_data)

	-- rpc nocb to scene
	local server_info = g_service_mgr:get_server_by_type(ServerType.SCENE)
	if not server_info then
		Log.warn("bridge_rpc_nocb_test server_info nil")
		return
	end
	local server_id = server_info._server_id

	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	g_rpc_mgr:call_nocb_by_server_id(server_id, "scene_rpc_nocb_test", rpc_data)

	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 2,
	}
	g_rpc_mgr:call_nocb_by_server_id(server_id, "scene_rpc_nocb_test", rpc_data)

end

local function bridge_rpc_mix_test(data)
	
	Log.debug("bridge_rpc_mix_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local index = data.index
	local sum = data.sum

	buff = buff .. "2"
	sum = sum + 1

	-- rpc to gate
	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.GATE, "gate_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("bridge_rpc_mix_test rpc call fail")
		return {result = ErrorCode.RPC_FAIL, buff=buff, sum=sum}
	end
	Log.debug("bridge_rpc_mix_test: callback ret=%s", Util.table_to_string(ret))
	buff = ret.buff
	sum = ret.sum

	-- rpc nocb gate
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	g_rpc_mgr:call_nocb_by_server_type(ServerType.GATE, "gate_rpc_nocb_test", rpc_data)

	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 2,
	}
	g_rpc_mgr:call_nocb_by_server_type(ServerType.GATE, "gate_rpc_nocb_test", rpc_data)


	local server_info = g_service_mgr:get_server_by_type(ServerType.SCENE)
	if not server_info then
		Log.warn("bridge_rpc_mix_test server_info nil")
		return
	end
	local server_id = server_info._server_id

	-- rpc nocb to scene
	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 1,
	}
	g_rpc_mgr:call_nocb_by_server_id(server_id, "scene_rpc_nocb_test", rpc_data)

	local rpc_data =
	{
		buff = buff,
		index = index,
		sum = 2,
	}
	g_rpc_mgr:call_nocb_by_server_id(server_id, "scene_rpc_nocb_test", rpc_data)
	
	-- rpc to scene
	local status, ret = g_rpc_mgr:call_by_server_id(server_id, "scene_rpc_test", {buff=buff, sum=sum})
	if not status then
		Log.err("bridge_rpc_mix_test rpc call fail")
		return {result = ErrorCode.RPC_FAIL, buff=buff, sum=sum}
	end
	Log.debug("bridge_rpc_mix_test: callback ret=%s", Util.table_to_string(ret))
	buff = ret.buff
	sum = ret.sum

	return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
end
-- ]

-----------------------------------------------------------

local function bridge_sync_gate_conn_num(data, mailbox_id)
	-- Log.debug("bridge_sync_gate_conn_num data=%s", Util.table_to_string(data))
	
	local server_info = g_service_mgr:get_server_by_mailbox(mailbox_id)
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

	g_common_mgr:sync_gate_conn_num(server_id, data.num)
end

-----------------------------------------------------------

local function bridge_create_role(data)
	
	Log.debug("bridge_create_role data=%s", Util.table_to_string(data))

	return g_common_mgr:rpc_create_role(data)
end

local function bridge_delete_role(data)
	
	Log.debug("bridge_delete_role: data=%s", Util.table_to_string(data))

	local user_id = data.user_id
	local role_id = data.role_id

	return g_common_mgr:rpc_delete_role(user_id, role_id)
end

local function bridge_select_role(data)
	
	Log.debug("bridge_select_role: data=%s", Util.table_to_string(data))

	local user_id = data.user_id
	local role_id = data.role_id

	return g_common_mgr:rpc_select_role(user_id, role_id)
end

local function register_rpc_handler()

	-- for test
	g_rpc_mgr:register_func("bridge_rpc_test", bridge_rpc_test)
	g_rpc_mgr:register_func("bridge_rpc_nocb_test", bridge_rpc_nocb_test)
	g_rpc_mgr:register_func("bridge_rpc_mix_test", bridge_rpc_mix_test)

	g_rpc_mgr:register_func("bridge_sync_gate_conn_num", bridge_sync_gate_conn_num)
	g_rpc_mgr:register_func("bridge_wait_connect_timeout", bridge_wait_connect_timeout)

	g_rpc_mgr:register_func("bridge_create_role", bridge_create_role)
	g_rpc_mgr:register_func("bridge_delete_role", bridge_delete_role)
	g_rpc_mgr:register_func("bridge_select_role", bridge_select_role)

end

register_rpc_handler()

