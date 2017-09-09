

local function register_rpc_handler()

	local call_func_map = RpcMgr._all_call_func

	call_func_map.scene_rpc_test = function(data)
		
		Log.debug("scene_rpc_test: data=%s", Util.table_to_string(data))

		local buff = data.buff
		local sum = data.sum

		buff = buff .. "4"
		sum = sum + 1

		return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
	end

end

register_rpc_handler()
