
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

	for table_name, table_struct in pairs(DataStructDef) do
		repeat
		Log.debug("table_name=%s table_struct=%s", table_name, Util.TableToString(table_struct))

		-- 1. create table
		-- 2. desc table
		-- 3. alter table
		-- 3.1 drop row
		-- 3.2 modify row
		-- 3.3 add row

		-- 1. create table
		local sql = string.format("CREATE TABLE IF NOT EXISTS %s (", table_name)
		local index = 0
		for field_name, field_cfg in pairs(table_struct) do
			repeat
			if not field_cfg.save or field_cfg.save == 0 then
				break
			end
			local line = ""
			index = index + 1
			if index ~= 1 then
				line = line .. ","
			end

			local field_type_str = type_str_map[field_cfg.type]
			local field_default = field_cfg.default
			if field_default ~= '_Null' then
				line = line .. string.format("%s %s DEFAULT '%s'", field_name, field_type_str, field_default)
			else
				line = line .. string.format("%s %s", field_name, field_type_str)
			end
			sql = sql .. line
			until true
		end

		if index == 0 then
			break
		end

		sql = sql .. ") ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_bin"
		Log.debug("sql=%s", sql)
		local ret = DBMgr.do_execute("game_db", sql, false)
		if not ret then
			Log.err("create table fail %s ", table_name)
			return false
		end
		Log.debug("create table success %s", table_name)

		-------------------------------------------------------------

		-- 2. desc table
		local sql = string.format("DESC %s", table_name)
		Log.debug("sql=%s", sql)
		local desc = DBMgr.do_execute("game_db", sql, true)
		if not desc then
			Log.err("desc table fail %s ", table_name)
			return false
		end
		Log.debug("desc=%s", Util.TableToString(desc))

		-------------------------------------------------------------

		-- 3. alter table
		local change_list = {}
		for _, field_info in ipairs(desc) do
			repeat
			local field_name = field_info.Field
			local field_type = field_info.Type
			local field_default = field_info.Default

			local field_cfg = table_struct[field_name]

			-- 3.1 drop row
			if not field_cfg or field_cfg.save == 0 then
				local str = string.format("DROP %s", field_name)
				table.insert(change_list, str)
				break
			end

			-- 3.2 modify row
			local config_field_type = type_str_map[field_cfg.type]
			local config_field_default = field_cfg.default

			if field_type == config_field_type 
			and field_default == config_field_default then
				break
			end
			local str = nil
			if config_field_default ~= '_Null' then
				str = string.format("MODIFY %s %s DEFAULT '%s'", field_name, config_field_type, config_field_default)
			else
				str = string.format("MODIFY %s %s", field_name, config_field_type)
			end
			table.insert(change_list, str)

			until true
		end

		for field_name, field_cfg in pairs(table_struct) do
			repeat
			-- 3.3 add row
			if not field_cfg.save or field_cfg.save == 0 then
				break
			end
			local is_exists = false
			for _, field_info in ipairs(desc) do
				if field_name == field_info.Field then
					is_exists = true
					break
				end
			end
			if not is_exists then
				local config_field_default = field_cfg.default
				local str = nil
				if config_field_default ~= '_Null' then
					str = string.format("ADD %s %s DEFAULT '%s'", field_name, type_str_map[field_cfg.type], config_field_default)
				else
					str = string.format("ADD %s %s", field_name, type_str_map[field_cfg.type])
				end
				table.insert(change_list, str)
			end
			until true
		end

		Log.debug("change_list=%s", Util.TableToString(change_list))
		if #change_list > 0 then
			local sql = string.format("ALTER TABLE %s ", table_name)
			for index, value in ipairs(change_list) do
				if index ~= 1 then
					sql = sql .. ","
				end
				sql = sql .. value
			end
			Log.debug("sql=%s", sql)
			local ret = DBMgr.do_execute("game_db", sql, false)
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
