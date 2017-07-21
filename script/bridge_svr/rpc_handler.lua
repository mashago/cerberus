

function register_rpc_handler()

	local function bridge_rpc_test(data)
		
		Log.debug("bridge_rpc_test: data=%s", Util.table_to_string(data))

		local buff = data.buff
		local sum = data.sum

		buff = buff .. "2"
		sum = sum + 1

		-- rpc to router
		local status, ret = RpcMgr.call_by_server_type(ServerType.ROUTER, "router_rpc_test", {buff=buff, sum=sum})
		if not status then
			Log.err("bridge_rpc_test rpc call fail")
			return {result = ErrorCode.RPC_FAIL, buff=buff, sum=sum}
		end
		Log.debug("bridge_rpc_test: callback ret=%s", Util.table_to_string(ret))
		buff = ret.buff
		sum = ret.sum

		-- rpc to scene
		local status, ret = RpcMgr.call_by_server_type(ServerType.SCENE, "scene_rpc_test", {buff=buff, sum=sum})
		if not status then
			Log.err("bridge_rpc_test rpc call fail")
			return {result = ErrorCode.RPC_FAIL, buff=buff, sum=sum}
		end
		Log.debug("bridge_rpc_test: callback ret=%s", Util.table_to_string(ret))
		buff = ret.buff
		sum = ret.sum

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
			table_name = "role_info",
			kvs = role_data,
		}
		Log.debug("bridge_create_role rpc_data=%s", Util.table_to_string(rpc_data))
		local status, ret = RpcMgr.call_by_server_type(ServerType.DB, "db_game_insert_one", rpc_data)
		if not status then
			Log.err("bridge_create_role rpc call fail")
			return {result = ErrorCode.SYS_ERROR}
		end
		Log.debug("bridge_create_role callback ret=%s", Util.table_to_string(ret))

		return {result = ret.result}

	end

	local function bridge_delete_role(data)
		
		Log.debug("bridge_delete_role: data=%s", Util.table_to_string(data))

		-- TODO check if role is online

		local role_id = data.role_id


		-- core logic, set is_delete in game_db.role_info
		local rpc_data = 
		{
			table_name = "role_info",
			fields = {is_delete = 1},
			conditions = {role_id=role_id}
		}
		local status, ret = RpcMgr.call_by_server_type(ServerType.DB, "db_game_update", rpc_data)
		if not status then
			Log.err("bridge_delete_role rpc call fail")
			return {result = ErrorCode.SYS_ERROR}
		end
		Log.debug("bridge_delete_role: callback ret=%s", Util.table_to_string(ret))

		return {result = ret.result}

	end

	local function bridge_select_role(data)
		
		Log.debug("bridge_select_role: data=%s", Util.table_to_string(data))

		-- TODO check if role is online
		-- 1. load scene_id from db
		-- 2. create a token
		-- 3. choose a router by user_id

		local user_id = data.user_id
		local role_id = data.role_id

		-- 1. load scene_id from db
		local rpc_data = 
		{
			table_name = "role_info",
			fields = {"scene_id"},
			conditions = {role_id=role_id}
		}
		local status, ret = RpcMgr.call_by_server_type(ServerType.DB, "db_game_select", rpc_data)
		if not status then
			Log.err("bridge_select_role rpc call fail")
			return {result = ErrorCode.SYS_ERROR}
		end
		Log.debug("bridge_select_role: callback ret=%s", Util.table_to_string(ret))

		if ret.result ~= ErrorCode.SUCCESS then
			return {result = ret.result}
		end

		if #ret.data ~= 1 or ret.data[1].scene_id == nil then
			Log.warning("bridge_select_role: role not exists %d %d", user_id, role_id)
			return {result = ErrorCode.ROLE_NOT_EXISTS}
		end

		local scene_id = tonumber(ret.data[1].scene_id)
		
		local token = "0000" -- TODO

		local rpc_data = 
		{
			user_id=user_id, 
			role_id=role_id, 
			scene_id=scene_id,
			token=token,
		}
		local status, ret = RpcMgr.call_by_server_type(ServerType.ROUTER, "router_select_role", rpc_data, user_id)
		if not status then
			Log.err("bridge_select_role rpc call fail")
			return {result = ErrorCode.SYS_ERROR}
		end
		Log.debug("bridge_select_role: callback ret=%s", Util.table_to_string(ret))
		if ret.result ~= ErrorCode.SUCCESS then
			return {result = ret.result}
		end

		local msg = 
		{
			result=ErrorCode.SUCCESS,
			ip=ret.ip,
			port=ret.port,
			token=token,
		}

		return msg

	end

	RpcMgr._all_call_func.bridge_rpc_test = bridge_rpc_test
	RpcMgr._all_call_func.bridge_create_role = bridge_create_role
	RpcMgr._all_call_func.bridge_delete_role = bridge_delete_role
	RpcMgr._all_call_func.bridge_select_role = bridge_select_role

end
