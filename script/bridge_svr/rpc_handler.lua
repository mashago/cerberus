

function register_rpc_handler()

	local function bridge_rpc_test(data)
		
		Log.debug("bridge_rpc_test: data=%s", Util.table_to_string(data))

		local buff = data.buff
		local sum = data.sum

		buff = buff .. "2"
		sum = sum + 1

		-- rpc to router
		local server_info = ServiceMgr.get_server_by_type(ServerType.ROUTER)
		if not server_info then
			Log.err("bridge_rpc_test no router server_info")
			return {result = ErrorCode.RPC_FAIL, buff=buff, sum=sum}
		end
		local status, result = RpcMgr.call(server_info, "router_rpc_test", {buff=buff, sum=sum})
		if not status then
			Log.err("bridge_rpc_test rpc call fail")
			return {result = ErrorCode.RPC_FAIL, buff=buff, sum=sum}
		end
		Log.debug("bridge_rpc_test: callback result=%s", Util.table_to_string(result))
		buff = result.buff
		sum = result.sum

		-- rpc to scene
		local server_info = ServiceMgr.get_server_by_type(ServerType.SCENE)
		if not server_info then
			Log.err("bridge_rpc_test no scene server_info")
			return {result = ErrorCode.RPC_FAIL, buff=buff, sum=sum}
		end
		local status, result = RpcMgr.call(server_info, "scene_rpc_test", {buff=buff, sum=sum})
		if not status then
			Log.err("bridge_rpc_test rpc call fail")
			return {result = ErrorCode.RPC_FAIL, buff=buff, sum=sum}
		end
		Log.debug("bridge_rpc_test: callback result=%s", Util.table_to_string(result))
		buff = result.buff
		sum = result.sum

		return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
	end

	-----------------------------------------------------------

	local function bridge_create_role(data)
		
		Log.debug("bridge_create_role: data=%s", Util.table_to_string(data))

		-- rpc to db to insert role_info
		local role_data = {}

		-- set default value by config
		for k, v in pairs(DataStructDef.game_db.role_info) do
			repeat
			if not v.save or v.save == 0 then
				break
			end
			local default = Util.convert_value_by_type(v.default, v.type)
			role_data[k]=default
			until true
		end
		Log.debug("bridge_create_role: data=%s", Util.table_to_string(data))

		-- set other value
		for k, v in pairs(data) do
			role_data[k] = v
		end

		local rpc_data =
		{
			db_name = "game_db",
			table_name = "role_info",
			kvs = role_data,
		}

		Log.debug("bridge_create_role rpc_data=%s", Util.table_to_string(rpc_data))

		local server_info = ServiceMgr.get_server_by_type(ServerType.DB, data.role_id)
		if not server_info then
			Log.err("bridge_create_role no db server_info")
			return {result = ErrorCode.SYS_ERROR}
		end

		local status, result = RpcMgr.call(server_info, "db_insert_one", rpc_data)
		if not status then
			Log.err("bridge_create_role rpc call fail")
			return {result = ErrorCode.SYS_ERROR}
		end
		Log.debug("bridge_create_role callback result=%s", Util.table_to_string(result))

		return {result = result.result}

	end

	RpcMgr._all_call_func.bridge_rpc_test = bridge_rpc_test
	RpcMgr._all_call_func.bridge_create_role = bridge_create_role

end
