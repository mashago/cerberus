local Log = require "log.logger"
local Util = require "util.util"
local class = require "util.class"
local g_funcs = require "global.global_funcs"

local Role = class()

function Role:ctor()
	self._attr = {}
	self._table_def = DataStructDef.data.role_info
end

function Role:init_data(attr_table)
	self._attr = {}
	g_funcs.attr_table_to_attr_map(self._table_def, attr_table, self._attr)
end

function Role:update_data(attr_table)
	g_funcs.attr_table_to_attr_map(self._table_def, attr_table, self._attr)
end

function Role:print()
	Log.info("******* Role:print *******")
	Log.info("_attr=%s", Util.table_to_string(self._attr))
end


return Role
