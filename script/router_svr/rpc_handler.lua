

function register_rpc_handler()

	local function router_rpc_test(data)
		
		Log.debug("router_rpc_test: data=%s", Util.table_to_string(data))

		local buff = data.buff
		local sum = data.sum

		buff = buff .. "3"
		sum = sum + 1

		return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
	end

	---------------------------------------------------------

	local function router_select_role(data)
		
		Log.debug("router_select_role: data=%s", Util.table_to_string(data))

		local user_id = data.user_id
		local role_id = data.role_id
		local scene_id = data.scene_id
		local token = data.token

		-- TODO check if already online, create user
		
		local msg =
		{
			result = ErrorCode.SUCCESS,
			ip=ServerConfig._ip,
			port=ServerConfig._port,
		}

		return msg
	end

	RpcMgr._all_call_func.router_rpc_test = router_rpc_test
	RpcMgr._all_call_func.router_select_role = router_select_role
end
