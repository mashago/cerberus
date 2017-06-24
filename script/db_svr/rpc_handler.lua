

function register_rpc_handler()
	RpcMgr._all_call_func.user_login = function(data)
		
		Log.debug("user_login: data=%s", Util.TableToString(data))
		return {result = 1, user_id = 1001}
	end
end
