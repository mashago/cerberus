

function register_rpc_handler()

	local function db_rpc_test(data)
		
		Log.debug("db_rpc_test: data=%s", Util.table_to_string(data))

		local buff = data.buff
		local sum = data.sum

		buff = buff .. "1"
		sum = sum + 1

		return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
	end

	--------------------------------------------------------

	local function db_user_login(data)
		
		Log.debug("db_user_login: data=%s", Util.table_to_string(data))

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

		Log.debug("db_user_login: ret=%s", Util.table_to_string(ret))
		if #ret == 0 then
			-- empty record, password mismatch
			return {result = ErrorCode.USER_LOGIN_PASSWORD_MISMATCH, user_id = 0}
		end
	
		-- must return a table
		local user_id = tonumber(ret[1].user_id)
		return {result = ErrorCode.SUCCESS, user_id = user_id}
	end

	local function db_create_role(data)
		
		Log.debug("db_create_role: data=%s", Util.table_to_string(data))

		local user_id = data.user_id
		local area_id = data.area_id
		local role_name = data.role_name
		local max_role = data.max_role

		-- call a procedure
		local sql = string.format("CALL create_user_role(%d,%d,'%s',%d)", user_id, area_id, role_name, max_role)

		local ret = DBMgr.do_execute("login_db", sql, true)
		if not ret then
			Log.err("db_create_role fail user_id=%d area_id=%d role_name=%s", user_id, area_id, role_name)
			return {result = ErrorCode.SUCCESS, role_id = 0}
		end

		Log.debug("db_create_role: ret=%s", Util.table_to_string(ret))
		local role_id = tonumber(ret[1].role_id)
		if role_id == -1 then
			return {result = ErrorCode.CREATE_ROLE_NUM_MAX, role_id = 0}
		elseif role_id == -2 then
			return {result = ErrorCode.CREATE_ROLE_DUPLICATE_NAME, role_id = 0}
		elseif role_id < 0 then
			Log.warn("db_create_role something go wrong role_id=%d user_id=%d area_id=%d role_name=%s", role_id, user_id, area_id, role_name)
			return {result = ErrorCode.CREATE_ROLE_FAIL, role_id = 0}
		end

		return {result = ErrorCode.SUCCESS, role_id = role_id}
	end


	local function db_select(data)
		
		Log.debug("db_insert: data=%s", Util.table_to_string(data))

		local db_name = data.db_name
		local table_name = data.table_name
		local fields = data.fields
		local conditions = data.conditions

		local ret = DBMgr.do_select(db_name, table_name, fields, conditions)
		if not ret then
			Log.err("db_select err db_name=%s table_name=%s fields=%s conditions=%s", db_name, table_name, Util.table_to_string(fields), Util.table_to_string(conditions))
			return {result = ErrorCode.SYS_ERROR, data = {}}
		end

		Log.debug("db_select: ret=%s", Util.table_to_string(ret))
	
		-- must return a table
		return {result = ErrorCode.SUCCESS, data = ret}
	end


	local function db_insert_one(data)
		
		Log.debug("db_insert: data=%s", Util.table_to_string(data))

		local db_name = data.db_name
		local table_name = data.table_name
		local kvs = data.kvs
		local get_id = data.get_id

		-- split kvs to {ks}, {{vs}}
		local fields = {}
		local values = {}
		for k, v in pairs(kvs) do
			table.insert(fields, k)
			table.insert(values, v)
		end
		local values_list = {values}

		local ret_data =
		{
			result = ErrorCode.SUCCESS,
		}

		local ret = DBMgr.do_insert(db_name, table_name, fields, values_list)
		if ret < 0 then
			ret_data.result = ErrorCode.SYS_ERROR
			return ret_data
		end

		if get_id then
			local insert_id = DBMgr.get_insert_id("db_name")
			result.insert_id = insert_id
		end

		return ret_data
	end


	RpcMgr._all_call_func.db_rpc_test = db_rpc_test

	RpcMgr._all_call_func.db_user_login = db_user_login
	RpcMgr._all_call_func.db_create_role = db_create_role
	RpcMgr._all_call_func.db_select = db_select
	RpcMgr._all_call_func.db_insert_one = db_insert_one
end
