

function register_rpc_handler()

	local call_func_map = RpcMgr._all_call_func

	call_func_map.db_user_login = function(data)
		
		Log.debug("db_user_login: data=%s", Util.TableToString(data))

		-- 1. insert account, if success, means register, return insert user_id
		-- 2. select account, if not success, means password mismatch

		local username = data.username
		local password = data.password
		local channel_id = data.channel_id

		local ret = DBMgr.do_insert("login_db", "user_info", {"username", "password", "channel_id"}, {{username, password, channel_id}})
		if ret > 0 then
			-- insert success
			local user_id = DBMgr.get_insert_id("login_db")
			return {result = ErrorCode.SUCCESS, user_id = user_id}
		end

		local ret = DBMgr.do_select("login_db", "user_info", {}
		, {username=username, password=password, channel_id=channel_id})
		if not ret then
			Log.warn("select user fail username=%s password=%s", username, password)
			return {result = ErrorCode.SYS_ERROR, user_id = 0}
		end

		Log.debug("db_user_login: ret=%s", Util.TableToString(ret))
		if #ret == 0 then
			-- empty record, password mismatch
			return {result = ErrorCode.USER_LOGIN_PASSWORD_MISMATCH, user_id = 0}
		end
	
		-- must return a table
		local user_id = ret[1].user_id
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
