

function register_rpc_handler()

	local call_func_map = RpcMgr._all_call_func

	call_func_map.db_user_login = function(data)
		
		Log.debug("db_user_login: data=%s", Util.TableToString(data))

		-- 1. select account
		-- 2. if not exists, insert account

		local ret = DBMgr.select("login_db", "user_info", {}, {user_name=data.username, user_password=data.password})
		if not ret then
			return {result = ErrorCode.SYS_ERROR, user_id = user_id}
		end

		Log.debug("db_user_login: ret=%s", Util.TableToString(ret))
	
		-- must return a table
		local user_id = math.random(10000)
		return {result = ErrorCode.SUCCESS, user_id = user_id}
	end

	call_func_map.db_rpc_test = function(data)
		
		Log.debug("db_rpc_test: data=%s", Util.TableToString(data))

		local buff = data.buff
		local sum = data.sum

		buff = buff .. "1"
		sum = sum + 1

		return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
	end


end
