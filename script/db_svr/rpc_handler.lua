

function register_rpc_handler()

	local call_func_map = RpcMgr._all_call_func

	call_func_map.db_rpc_test = function(data)
		
		Log.debug("db_rpc_test: data=%s", Util.TableToString(data))

		local buff = data.buff
		local sum = data.sum

		buff = buff .. "1"
		sum = sum + 1

		return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
	end

	--------------------------------------------------------

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
		local user_id = tonumber(ret[1].user_id)
		return {result = ErrorCode.SUCCESS, user_id = user_id}
	end

	call_func_map.db_role_list = function(data)
		
		Log.debug("db_role_list: data=%s", Util.TableToString(data))

		local area_id = data.area_id
		local user_id = data.user_id

		local ret = DBMgr.do_select("login_db", "user_role", {"role_id", "role_name"}
		, {user_id=user_id, area_id=area_id})
		if not ret then
			Log.warn("select role_list fail username=%s password=%s", username, password)
			return {result = ErrorCode.SYS_ERROR, role_list = {}}
		end

		Log.debug("db_role_list: ret=%s", Util.TableToString(ret))

		local role_list = {}
		for _, r in ipairs(ret) do
			local role_info = {}
			role_info.role_id = tonumber(r.role_id)
			role_info.role_name = r.role_name
			table.insert(role_list, role_info)
		end
	
		-- must return a table
		return {result = ErrorCode.SUCCESS, role_list = role_list}
	end

	call_func_map.db_create_role = function(data)
		
		Log.debug("db_create_role: data=%s", Util.TableToString(data))


		local user_id = data.user_id
		local area_id = data.area_id
		local role_name = data.role_name

		-- TODO call a procedure

		local ret = DBMgr.do_insert("login_db", "user_role", {"user_id", "area_id", "role_name"}, {{user_id, area_id, role_name}})
		if ret < 0 then
			-- insert fail, should be duplicate role_name
			return {result = ErrorCode.CREATE_ROLE_DUPLICATE_NAME, role_id = 0}
		end

		local role_id = DBMgr.get_insert_id("login_db")
		return {result = ErrorCode.SUCCESS, role_id = role_id}
	end

end
