
local SheetObj = class()

function SheetObj:ctor(sheet_name, key)
	
	self._sheet_name = sheet_name
	self._table_def = DataStructDef.data[sheet_name]
	assert(self._table_def, "SheetObj:ctor no such sheet " .. sheet_name)

	self._key = key
	self._key_name = nil
	self._second_key_name = nil
	for _, field_def in ipairs(self._table_def) do
		if field_def.key == 1 then
			self._key_name = field_def.field
		elseif field_def.key == 2 then
			self._second_key_name = field_def.field
		end
	end
	assert(self._key_name, "SheetObj:ctor sheet no key " .. sheet_name)

end

function SheetObj:get_db_data()

	local rpc_data = 
	{
		table_name = "role_info",
		fields = {},
		self._key_name = self._key
	}

	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_game_select", rpc_data, self._key)
	if not status then
		Log.err("SheetObj:get_db_data fail")
		return false
	end

	if ret.result ~= ErrorCode.SUCCESS then
		Log.err("SheetObj:get_db_data error %d", ret.result)
		return false
	end

	return ret.data
end

function SheetObj:init_data(db_record)
	self._attr = {}

	-- init not-db attr to default value
	local attr_map = {}
	for _, field_def in ipairs(self._table_def) do
		if field_def.save == 0 then
			local value = g_funcs.str_to_value(field_def.default, field_def.type)
			attr_map[field_def.field] = value
		end
	end

	if not self._second_key_name then
		-- only one row
		-- init from db_record
		for k, v in pairs(db_record) do
			attr_map[k] = v
		end
		self._attr = attr_map
	else
		-- multi row
		for _, row in ipairs(db_record) do
			local sub_attr_map = {}
			for k, v in pairs(attr_map) do
				sub_attr_map[k] = v
			end
			for k, v in pairs(row) do
				sub_attr_map[k] = v
			end
			self._attr[sub_attr_map[self._second_key_name]] = sub_attr_map
		end
	end
end

function SheetObj:modify_attr(attr_name, ...)
end

function SheetObj:db_save(is_timeout)
end

return SheetObj
