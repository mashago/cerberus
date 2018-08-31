
local Log = require "core.log.logger"
local Util = require "core.util.util"
local sheet_name = "test_role"
local class = require "core.util.class"
local g_funcs = require "core.global.global_funcs"
local SheetObj = require "core.obj.sheet_obj"

local TestRole = class(SheetObj)


function TestRole:ctor(role_id)
	self._role_id = role_id
end

function TestRole:init()
	self:init_sheet(sheet_name, {self._role_id})
end

function TestRole:test_func()
	local a = 123
	Log.debug("TestRole:test_func %s", Util.table_to_string(SheetObj))
	-- SheetObj.test_func(a)
	Log.debug("TestRole:test_func %s", Util.table_to_string({a}))
end

function TestRole:do_save(insert_rows, delete_rows, modify_rows)
	Log.debug("#### TestRole:do_save ####")
	Log.debug("insert_rows=%s", Util.table_to_string(insert_rows))
	Log.debug("delete_rows=%s", Util.table_to_string(delete_rows))
	Log.debug("modify_rows=%s", Util.table_to_string(modify_rows))
	Log.debug("##########################")
end

g_funcs.register_getter_setter(TestRole, sheet_name)

return TestRole
