
local Role = class()

function Role:ctor(role_id)
	self._role_id = role_id
	self._attr = {}
end

function Role:init_data(attr_table)
	local table_def = DataStructDef.data.role_info
	g_funcs.attr_table_to_attr_map(table_def, attr_table, self._attr)
end

function Role:update_data(attr_table)
	local table_def = DataStructDef.data.role_info
	g_funcs.attr_table_to_attr_map(table_def, attr_table, self._attr)
end

function Role:print()
	Log.info("******* Role:print *******")
	Log.info("role_id=%d", self._role_id)
	Log.info("_attr=%s", Util.table_to_string(self._attr))
end


return Role
