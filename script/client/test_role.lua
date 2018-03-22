
local sheet_name = "test_role"

TestRole = class(SheetObj)


function TestRole:ctor(role_id)
	self._role_id = role_id
end

function TestRole:init()
	function change_cb(...)
		Log.debug("change_cb %s", Util.table_to_string({...}))
	end
	function sync_func(...)
		Log.debug("sync_func %s", Util.table_to_string({...}))
	end
	function save_func(...)
		Log.debug("save_func %s", Util.table_to_string({...}))
	end
	self:init_sheet(sheet_name, {self._role_id}, change_cb, sync_func, save_func)
end

g_funcs.register_getter_setter(TestRole, sheet_name)
