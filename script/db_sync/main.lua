
local do_db_sync = nil

local function main_entry()
	Log.info("sync_db main_entry")

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	g_funcs.connect_to_mysql(xml_doc)

	-- sync db
	do_db_sync()
	
end

do_db_sync = function()
	Log.debug("do_db_sync")

	local type_str_map = 
	{
		[_Byte] = "int(11)",
		[_Bool] = "int(11)",
		[_Int] = "int(11)",
		[_Float] = "float(11)",
		[_Short] = "int(11)",
		[_Int64] = "bigint(20)",
		[_String] = "varchar(255)",
		[_Struct] = "blob",
	}

	for table_name, t in pairs(DataStructDef) do
		repeat
		Log.debug("table_name=%s t=%s", table_name, Util.TableToString(t))

		-- make create table sql
		local sql = string.format("CREATE TABLE IF NOT EXISTS %s (", table_name)

		local index = 0
		for field, params in pairs(t) do
			repeat
			if not params.save or params.save ~= 1 then
				break
			end
			local line = ""
			index = index + 1
			if index ~= 1 then
				line = line .. ","
			end

			local field_type_str = type_str_map[params.type]
			line = line .. string.format("%s %s", field, field_type_str)
			sql = sql .. line
			until true
		end

		if index == 0 then
			break
		end

		sql = sql .. ") ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_bin"

		Log.debug("sql=%s", sql)

		-- make alter table sql
		local sql = string.format("DESC %s", table_name)
		local ret = DBMgr.do_execute("game_db", sql, true)
		Log.debug("ret=%s", Util.TableToString(ret))

		until true
	end

	

end

main_entry()
