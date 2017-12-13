
DBProxy = {}

function DBProxy.send_delete(db_name, table_name, conditions, opt_key)
	local data = 
	{
		db_name = db_name,
		table_name = table_name,
		conditions = Util.serialize(conditions),
	}

	return g_service_mgr:send_by_server_type(ServerType.DB, MID.DB_DELETE, data, opt_key)
end

return DBProxy
