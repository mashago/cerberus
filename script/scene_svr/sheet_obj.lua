
local SheetObj = class()

function SheetObj:ctor(sheet_name, key)
	
	self._sheet_name = sheet_name
	self._table_def = DataStructDef.data[sheet_name]
	assert(self._table_def, "SheetObj:ctor no such sheet " .. sheet_name)

	self._key = key
	self._key_name = nil
	for _, field_def in ipairs(self._table_def) do
		if field_def.key == 1 then
			self._key_name = field_def.field
			break
		end
	end
	assert(self._key_name, "SheetObj:ctor sheet no key " .. sheet_name)

end

function SheetObj:load_db(condition)

	local rpc_data = 
	{
		table_name = "role_info",
		fields = {},
		conditions = condition
	}

	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_game_select", rpc_data, self._role_id)
	if not status then
		Log.err("Role:load_db fail")
		return false
	end

	if ret.result ~= ErrorCode.SUCCESS then
		Log.err("Role:load_db error %d", ret.result)
		return false
	end

end

function SheetObj:db_save(is_timeout)
end

return SheetObj
