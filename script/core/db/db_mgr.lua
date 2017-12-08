
DBMgr = 
{
	_mysql_map = {}, -- {[db_name] = mysqlmgr}
}


function DBMgr.connect_to_mysql(ip, port, username, password, db_name)
	local mysqlmgr = LuaMysqlMgr.create()
	local ret = mysqlmgr:connect(ip, port, username, password, db_name)
	if ret ~= 0 then
		Log.err("connect_to_mysql fail %d [%d] [%s]", ret, mysqlmgr:get_errno(), mysqlmgr:get_error())
		return false
	end

	DBMgr._mysql_map[db_name] = mysqlmgr
	return true
end


-- local ret = DBMgr.do_select("login_db", "user_info", {}, {username=username, password=password, channel_id=channel_id})
-- db_name = "login_db"
-- table_name = "user_info"
-- fields = {} or {"user_id", "user_name"}
-- conditions = {} or {"user_name"="masha", "user_password"="123456"}
-- return data table, or nil for error
function DBMgr.do_select(db_name, table_name, fields, conditions)
	Log.debug("db_name=%s", db_name)
	Log.debug("table_name=%s", table_name)
	Log.debug("fields=%s", Util.table_to_string(fields))
	Log.debug("conditions=%s", Util.table_to_string(conditions))

	local mysqlmgr = DBMgr._mysql_map[db_name] 
	if not mysqlmgr then
		return nil
	end

	local sql = "SELECT "
	-- handle field
	if fields and #fields > 0 then
		for k, v in ipairs(fields) do
			if k ~= 1 then
				sql = sql .. ","
			end
			sql = sql .. v
		end
	else
		sql = sql .. "*"
	end
	sql = sql .. " FROM " .. table_name

	-- handle condition
	if conditions and next(conditions) then
		sql = sql .. " WHERE "
		local index = 1
		for k, v in pairs(conditions) do
			if index ~= 1 then
				sql = sql .. " AND "
			end
			sql = sql .. k .. "="
			if type(v) == "string" then
				sql = sql .. "'" .. v .. "'"
			else
				sql = sql .. v
			end
			index = index + 1
		end
	end
	Log.debug("sql=%s", sql)

	local ret, data = mysqlmgr:select(sql)
	if not ret then
		return nil
	end
	
	return data
end

-- local ret = DBMgr.do_insert("login_db", "user_info", {"username", "password", "channel_id"}, {{username, password, channel_id}})
-- db_name = "login_db"
-- table_name = "user_info"
-- fields = {"user_name", "user_password"}
-- values = {{"masha", "123456"}, {...}}
-- return affected row nums, or negative for error
function DBMgr.do_insert(db_name, table_name, fields, values)
	Log.debug("DBMgr.do_insert: db_name=%s", db_name)
	Log.debug("DBMgr.do_insert: table_name=%s", table_name)
	Log.debug("DBMgr.do_insert: fields=%s", Util.table_to_string(fields))
	Log.debug("DBMgr.do_insert: values=%s", Util.table_to_string(values))

	local mysqlmgr = DBMgr._mysql_map[db_name] 
	if not mysqlmgr then
		return -1
	end

	if not fields or #fields == 0 or not values or #values == 0 then
		return -1
	end

	local sql = "INSERT INTO " .. table_name .. " ("

	-- handle field
	for k, v in ipairs(fields) do
		if k ~= 1 then
			sql = sql .. ","
		end
		sql = sql .. v
	end
	sql = sql .. ") VALUES "
	Log.debug("111 sql=%s", sql)

	-- handle condition
	for k, t in ipairs(values) do
		if #t ~= #fields then
			return -1
		end
		if k ~= 1 then
			sql = sql .. ","
		end
		sql = sql .. "("
		for i, v in ipairs(t) do
			if i ~= 1 then
				sql = sql .. ","
			end
			if type(v) == "string" then
				sql = sql .. "'" .. v .. "'"
			elseif type(v) == "table" then
				Log.debug("x=%s", Util.serialize(v))
				sql = sql .. "'" .. Util.serialize(v) .. "'"
			elseif type(v) == "boolean" then
				sql = sql .. tostring(v)
			else
				sql = sql .. v
			end
		end
		sql = sql .. ")"
	end
	Log.debug("222 sql=%s", sql)

	local ret = mysqlmgr:change(sql)
	
	return ret
end

function DBMgr.get_insert_id(db_name)
	Log.debug("db_name=%s", db_name)

	local mysqlmgr = DBMgr._mysql_map[db_name] 
	if not mysqlmgr then
		return -1
	end

	local insert_id = math.floor(mysqlmgr:get_insert_id())
	return insert_id
end

-- local ret = DBMgr.do_delete("login_db", "user_role", {role_id=role_id})
-- db_name = "login_db"
-- table_name = "user_info"
-- conditions = {role_id=role_id}
-- return affected row nums, or negative for error
function DBMgr.do_delete(db_name, table_name, conditions)
	Log.debug("db_name=%s", db_name)
	Log.debug("table_name=%s", table_name)
	Log.debug("conditions=%s", Util.table_to_string(conditions))

	local mysqlmgr = DBMgr._mysql_map[db_name] 
	if not mysqlmgr then
		return -1
	end

	local sql = "DELETE FROM " .. table_name

	-- handle condition
	if next(conditions) then
		sql = sql .. " WHERE "

		local index = 1
		for k, v in pairs(conditions) do
			if index ~= 1 then
				sql = sql .. " AND "
			end
			sql = sql .. k .. "="
			if type(v) == "string" then
				sql = sql .. "'" .. v .. "'"
			else
				sql = sql .. v
			end
			index = index + 1
		end

	end

	Log.debug("sql=%s", sql)

	local ret = mysqlmgr:change(sql)
	
	return ret
end

-- local ret = DBMgr.do_update("login_db", "user_role", {is_delete=1}, {role_id=role_id})
-- db_name = "login_db"
-- table_name = "user_info"
-- fields = {is_delete=1}
-- conditions = {role_id=role_id}
-- return affected row nums, or negative for error
function DBMgr.do_update(db_name, table_name, fields, conditions)
	Log.debug("db_name=%s", db_name)
	Log.debug("table_name=%s", table_name)
	Log.debug("fields=%s", Util.table_to_string(fields))
	Log.debug("conditions=%s", Util.table_to_string(conditions))

	local mysqlmgr = DBMgr._mysql_map[db_name] 
	if not mysqlmgr then
		return -1
	end

	if not next(fields) then
		Log.warn("DBMgr.do_update fields empty table_name=%s", table_name)
		return -1
	end

	local sql = "UPDATE " .. table_name .. " SET "

	-- handle fields
	local index = 1
	for k, v in pairs(fields) do
		if index ~= 1 then
			sql = sql .. ","
		end
		sql = sql .. k .. "="
		if type(v) == "string" then
			sql = sql .. "'" .. v .. "'"
		else
			sql = sql .. v
		end
		index = index + 1
	end


	-- handle condition
	if next(conditions) then
		sql = sql .. " WHERE "

		local index = 1
		for k, v in pairs(conditions) do
			if index ~= 1 then
				sql = sql .. " AND "
			end
			sql = sql .. k .. "="
			if type(v) == "string" then
				sql = sql .. "'" .. v .. "'"
			else
				sql = sql .. v
			end
			index = index + 1
		end

	end

	Log.debug("sql=%s", sql)

	local ret = mysqlmgr:change(sql)
	
	return ret
end

-- for execute raw sql
function DBMgr.do_execute(db_name, sql, has_ret)

	local mysqlmgr = DBMgr._mysql_map[db_name] 
	if not mysqlmgr then
		return nil
	end
	if has_ret then
		local ret, data = mysqlmgr:select(sql)
		if not ret then
			return nil
		end
		return data
	end

	local ret = mysqlmgr:change(sql)
	return ret
end

return DBMgr
