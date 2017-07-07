

function register_rpc_handler()

	local function router_rpc_test(data)
		
		Log.debug("router_rpc_test: data=%s", Util.TableToString(data))

		local buff = data.buff
		local sum = data.sum

		buff = buff .. "3"
		sum = sum + 1

		return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
	end

	RpcMgr._all_call_func.router_rpc_test = router_rpc_test
end
