

function g_rpc_mgr.db_rpc_test(data)
	Log.debug("db_rpc_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local sum = data.sum

	buff = buff .. "1"
	sum = sum + 1

	return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
end


function g_rpc_mgr.db_rpc_nocb_test(data)
	Log.debug("db_rpc_nocb_test: data=%s", Util.table_to_string(data))

	XXX_g_rpc_nocb_map = XXX_g_rpc_nocb_map or {}
	local buff = data.buff
	local index = data.index
	local sum = data.sum

	local last_sum = XXX_g_rpc_nocb_map[index]
	if not node then
		XXX_g_rpc_nocb_map[index] = sum
		return
	end

	if sum < last_sum then
		Log.err("db_rpc_nocb_test bug index=%d sum=%d last_sum=%d", index, sum, last_sum)
		return
	end

	XXX_g_rpc_nocb_map[index] = sum
end

--------------------------------------------------------

function g_rpc_mgr.db_user_login(data)
	
	Log.debug("db_user_login: data=%s", Util.table_to_string(data))

	-- 1. insert account, if success, means register, return insert user_id
	-- 2. select account, if not success, means password mismatch

	local db_name = g_server_conf._db_name_map[DBType.LOGIN]
	local username = data.username
	local password = data.password
	local channel_id = data.channel_id

	local ret = DBMgr.do_insert(db_name, "user_info", {"username", "password", "channel_id"}, {{username, password, channel_id}})
	if ret > 0 then
		-- insert success
		local user_id = DBMgr.get_insert_id(db_name)
		return {result = ErrorCode.SUCCESS, user_id = user_id}
	end

	local ret = DBMgr.do_select(db_name, "user_info", {}
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

function g_rpc_mgr.db_create_role(data)
	
	Log.debug("db_create_role: data=%s", Util.table_to_string(data))

	local db_name = g_server_conf._db_name_map[DBType.LOGIN]
	local user_id = data.user_id
	local area_id = data.area_id
	local role_name = data.role_name
	local max_role = data.max_role

	-- call a procedure
	local sql = string.format("CALL create_user_role(%d,%d,'%s',%d)", user_id, area_id, role_name, max_role)

	local ret = DBMgr.do_execute(db_name, sql, true)
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

-------------------------------------------------

local function db_select(data)
	
	Log.debug("db_select: data=%s", Util.table_to_string(data))

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

local function db_insert(data)
	
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

local function db_insert_multi(data)

	local ret_data =
	{
		result = ErrorCode.SUCCESS,
	}

	-- fix to call db_insert
	local kvs_list = data.kvs_list
	for _, v in ipairs(kvs_list) do
		data.kvs = v
		local ret = db_insert(data)
		if ret.result ~= ErrorCode.SYS_ERROR then
			ret_data.result = ErrorCode.SYS_ERROR
			break
		end
	end

	return ret_data
end

local function db_delete(data)
	
	Log.debug("db_delete: data=%s", Util.table_to_string(data))

	local db_name = data.db_name
	local table_name = data.table_name
	local conditions = data.conditions

	local ret = DBMgr.do_delete(db_name, table_name, conditions)
	if ret < 0 then
		Log.err("db_delete err db_name=%s table_name=%s conditions=%s", db_name, table_name, Util.table_to_string(conditions))
		return {result = ErrorCode.SYS_ERROR}
	end
	if ret == 0 then
		Log.warn("db_delete nothing change db_name=%s table_name=%s conditions=%s", db_name, table_name, Util.table_to_string(conditions))
	end

	Log.debug("db_delete: ret=%d", ret)

	-- must return a table
	return {result = ErrorCode.SUCCESS}
end

local function db_delete_multi(data)

	local ret_data =
	{
		result = ErrorCode.SUCCESS,
	}

	-- fix to call db_delete
	local conditions_list = data.conditions_list
	for _, v in ipairs(conditions_list) do
		data.conditions = v
		local ret = db_delete(data)
		if ret.result ~= ErrorCode.SYS_ERROR then
			ret_data.result = ErrorCode.SYS_ERROR
			break
		end
	end

	return ret_data
end

local function db_update(data)
	
	Log.debug("db_update: data=%s", Util.table_to_string(data))

	local db_name = data.db_name
	local table_name = data.table_name
	local fields = data.fields
	local conditions = data.conditions

	local ret = DBMgr.do_update(db_name, table_name, fields, conditions)
	if ret < 0 then
		Log.err("db_update err db_name=%s table_name=%s fields=%s conditions=%s", db_name, table_name, Util.table_to_string(fields), Util.table_to_string(conditions))
		return {result = ErrorCode.SYS_ERROR}
	end
	if ret == 0 then
		Log.warn("db_update nothing change db_name=%s table_name=%s fields=%s conditions=%s", db_name, table_name, Util.table_to_string(fields), Util.table_to_string(conditions))
	end

	Log.debug("db_update: ret=%d", ret)

	-- must return a table
	return {result = ErrorCode.SUCCESS}
end

local function db_update_multi(data)
	local ret_data =
	{
		result = ErrorCode.SUCCESS,
	}

	-- fix to call db_update
	local modify_list = data.modify_list
	for _, v in ipairs(modify_list) do
		data.fields = v[1]
		data.conditions = v[2]
		local ret = db_update(data)
		if ret.result ~= ErrorCode.SYS_ERROR then
			ret_data.result = ErrorCode.SYS_ERROR
			break
		end
	end

	return ret_data
end

------------------------------------------------------

function g_rpc_mgr.db_login_select(data)
	
	local db_name = g_server_conf._db_name_map[DBType.LOGIN]
	data.db_name = db_name
	return db_select(data)
end

function g_rpc_mgr.db_login_insert(data)
	
	local db_name = g_server_conf._db_name_map[DBType.LOGIN]
	data.db_name = db_name
	return db_insert(data)
end

function g_rpc_mgr.db_login_delete(data)
	
	local db_name = g_server_conf._db_name_map[DBType.LOGIN]
	data.db_name = db_name
	return db_delete(data)
end

function g_rpc_mgr.db_login_update(data)
	
	local db_name = g_server_conf._db_name_map[DBType.LOGIN]
	data.db_name = db_name
	return db_update(data)
end

-- will convert data by DataStructDef
function g_rpc_mgr.db_game_select(data)
	
	local db_name = g_server_conf._db_name_map[DBType.GAME]
	data.db_name = db_name

	local ret = db_select(data)
	if ret.result ~= ErrorCode.SUCCESS then
		return ret
	end
	if #ret.data == 0 then
		return ret
	end

	Log.debug("db_game_select ret=%s", Util.table_to_string(ret))
	
	-- convert to data def type
	local table_name = data.table_name
	local table_def = DataStructDef.data[table_name]
	if not table_def then
		Log.warn("db_game_select no such table define [%d]", table_name)
		return ret
	end

	-- pick first line to get field type
	local type_map = {} -- [field]=type
	local line = ret.data[1]
	for field, str_value in pairs(line) do
		local field_def = table_def[field]
		if field_def then
			type_map[field] = field_def.type
		else
			Log.warn("db_game_select unknow field %s", field)
		end
	end

	-- convert data from str to value
	for _, line in ipairs(ret.data) do
		for field, str_value in pairs(line) do
			line[field] = g_funcs.str_to_value(str_value, type_map[field])
		end
	end

	Log.debug("db_game_select ret2=%s", Util.table_to_string(ret))
	return ret
end

function g_rpc_mgr.db_game_insert(data)
	
	local db_name = g_server_conf._db_name_map[DBType.GAME]
	data.db_name = db_name
	return db_insert(data)
end

function g_rpc_mgr.db_game_insert_multi(data)
	
	local db_name = g_server_conf._db_name_map[DBType.GAME]
	data.db_name = db_name
	return db_insert_multi(data)
end

function g_rpc_mgr.db_game_delete(data)
	
	local db_name = g_server_conf._db_name_map[DBType.GAME]
	data.db_name = db_name
	return db_delete(data)
end

function g_rpc_mgr.db_game_delete_multi(data)
	
	local db_name = g_server_conf._db_name_map[DBType.GAME]
	data.db_name = db_name
	return db_delete_multi(data)
end

function g_rpc_mgr.db_game_update(data)
	
	local db_name = g_server_conf._db_name_map[DBType.GAME]
	data.db_name = db_name
	return db_update(data)
end

function g_rpc_mgr.db_game_update_multi(data)
	
	local db_name = g_server_conf._db_name_map[DBType.GAME]
	data.db_name = db_name
	return db_update_multi(data)
end

