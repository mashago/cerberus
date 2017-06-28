
DBMgr = {}

DBMgr._mysql_map = {} -- {[db_name] = mysqlmgr}

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

return DBMgr
