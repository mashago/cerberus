
local sync_db = nil

local function main_entry()
	Log.info("sync_db main_entry")

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	g_funcs.connect_to_mysql(xml_doc)

	-- sync db
	sync_db()
	
end

sync_db = function()
	Log.debug("sync_db")

	local type_str_map = 
	{
		[_Byte] = "int(11)",
		[_Bool] = "boolean",
		[_Int] = "int(11)",
		[_Float] = "float(11)",
		[_Short] = "int(11)",
		[_Int64] = "bigint(20)",
		[_String] = "varchar(255)",
		[_Struct] = "blob",
	}

	local db_name = ServerConfig._db_name_map[DBType.GAME]
	Log.debug("db_name=%s", db_name)

	for table_name, table_def in pairs(DataStructDef.data) do
		repeat
		-- Log.debug("table_name=%s table_def=%s", table_name, Util.table_to_string(table_def))

		-- 1. create table
		-- 2. desc table
		-- 3. alter table
		-- 3.1 drop row
		-- 3.2 modify row
		-- 3.3 add row
		-- 4. desc table again, for update key
		-- 5. update key

		-- 1. create table
		local sql = string.format("CREATE TABLE IF NOT EXISTS %s (", table_name)
		local i = 0
		local key_map = {}
		for _, field_def in ipairs(table_def) do
			repeat
			local field_name = field_def.field
			if not field_def.save or field_def.save == 0 then
				break
			end
			local line = ""
			i = i + 1
			if i ~= 1 then
				line = line .. ","
			end

			local field_type_str = type_str_map[field_def.type]
			local field_default = field_def.default
			if field_default ~= '_Null' and field_def.type ~= _Struct then
				line = line .. string.format("%s %s DEFAULT '%s'", field_name, field_type_str, field_default)
			else
				line = line .. string.format("%s %s", field_name, field_type_str)
			end

			-- mark key field
			if field_def.key and field_def.key == 1 then
				key_map[field_name] = true
			end

			sql = sql .. line
			until true
		end

		if i == 0 then
			break
		end

		-- point key field
		for field_name, __ in pairs(key_map) do
			local line = string.format(",KEY `%s` (`%s`)", field_name, field_name)
			sql = sql .. line
		end

		sql = sql .. ") ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_bin"
		Log.debug("sql=%s", sql)
		local ret = DBMgr.do_execute(db_name, sql, false)
		if not ret then
			Log.err("create table fail %s ", table_name)
			return false
		end
		Log.debug("create table success %s", table_name)

		-------------------------------------------------------------

		-- 2. desc table
		local sql = string.format("DESC %s", table_name)
		Log.debug("sql=%s", sql)
		local desc = DBMgr.do_execute(db_name, sql, true)
		if not desc then
			Log.err("desc table fail %s ", table_name)
			return false
		end
		-- Log.debug("desc=%s", Util.table_to_string(desc))

		-------------------------------------------------------------

		-- 3. alter table
		local change_list = {}
		for _, field_info in ipairs(desc) do
			repeat
			local db_field_name = field_info.Field
			local db_field_type = field_info.Type
			local db_field_default = field_info.Default

			local field_def = nil
			for __, t in ipairs(table_def) do
				if t.field == db_field_name then
					field_def = t
					break
				end
			end

			-- 3.1 drop row
			if not field_def or field_def.save == 0 then
				local str = string.format("DROP %s", db_field_name)
				table.insert(change_list, str)
				break
			end

			-- 3.2 modify row
			local config_field_type = type_str_map[field_def.type]
			local config_field_default = field_def.default

			if db_field_type == config_field_type then
				if  db_field_default == config_field_default then
					break
				elseif db_field_type == 'blob' then
					-- struct default is not for db
					break
				end
			end

			local str = nil
			if config_field_default ~= '_Null' and field_def.type == _Struct then
				str = string.format("MODIFY %s %s DEFAULT '%s'", db_field_name, config_field_type, config_field_default)
			else
				str = string.format("MODIFY %s %s", db_field_name, config_field_type)
			end
			table.insert(change_list, str)

			until true
		end

		for _, field_def in ipairs(table_def) do
			repeat
			local field_name = field_def.field
			-- 3.3 add row
			if not field_def.save or field_def.save == 0 then
				break
			end
			local is_exists = false
			for _, field_info in ipairs(desc) do
				if field_name == field_info.Field then
					is_exists = true
					break
				end
			end
			if is_exists then
				break
			end
			local config_field_default = field_def.default
			local str = nil
			if config_field_default ~= '_Null' then
				str = string.format("ADD %s %s DEFAULT '%s'", field_name, type_str_map[field_def.type], config_field_default)
			else
				str = string.format("ADD %s %s", field_name, type_str_map[field_def.type])
			end
			table.insert(change_list, str)
			until true
		end

		-- Log.debug("change_list=%s", Util.table_to_string(change_list))
		if #change_list > 0 then
			local sql = string.format("ALTER TABLE %s ", table_name)
			for i, value in ipairs(change_list) do
				if i ~= 1 then
					sql = sql .. ","
				end
				sql = sql .. value
			end
			Log.debug("sql=%s", sql)
			local ret = DBMgr.do_execute(db_name, sql, false)
			if ret < 0 then
				Log.err("alter table fail %s ", table_name)
				return false
			end
		end

		-------------------------------------------------------------

		-- 4. desc table
		local sql = string.format("DESC %s", table_name)
		Log.debug("sql=%s", sql)
		local desc = DBMgr.do_execute(db_name, sql, true)
		if not desc then
			Log.err("desc table fail %s ", table_name)
			return false
		end
		-- Log.debug("desc=%s", Util.table_to_string(desc))

		-------------------------------------------------------------

		-- 5. update key
		local change_list = {}
		for _, field_info in ipairs(desc) do
			-- drop not exists key
			if field_info.Key == 'MUL' and not key_map[field_info.Field] then
				local str = string.format("DROP INDEX %s", field_info.Field)
				table.insert(change_list, str)
			end
		end

		-- add key
		for _, field_def in ipairs(table_def) do
			repeat
			local field_name = field_def.field
			if not field_def.save or field_def.save == 0 or not field_def.key or field_def.key == 0 then
				break
			end
			local is_set = false
			for _, field_info in ipairs(desc) do
				if field_name == field_info.Field and field_info.Key == 'MUL' then
					is_set = true
					break
				end
			end
			if is_set then
				break
			end
			local str = string.format("ADD INDEX %s (%s)", field_name, field_name)
			table.insert(change_list, str)
			until true
		end

		-- Log.debug("change_list=%s", Util.table_to_string(change_list))
		if #change_list > 0 then
			local sql = string.format("ALTER TABLE %s ", table_name)
			for i, value in ipairs(change_list) do
				if i ~= 1 then
					sql = sql .. ","
				end
				sql = sql .. value
			end
			Log.debug("sql=%s", sql)
			local ret = DBMgr.do_execute(db_name, sql, false)
			if ret < 0 then
				Log.err("alter table fail %s ", table_name)
				return false
			end
		end

		until true
	end

	return true
end

main_entry()
