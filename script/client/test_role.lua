
local sheet_name = "test_role"

TestRole = class(SheetObj)


function TestRole:ctor(role_id)
	self._role_id = role_id
end

function TestRole:init()
	function change_cb(...)
		Log.debug("change_cb %s", Util.table_to_string({...}))
	end
	self:init_sheet(sheet_name, change_cb, self._role_id)
end

g_funcs.register_getter_setter(TestRole, sheet_name)
