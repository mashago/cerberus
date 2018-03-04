
local SheetObj = class()

function SheetObj:ctor(sheet_name)
	
	self.table_def = DataStructDef.data[sheet_name]
	assert(self.table_def, "SheetObj:ctor no such sheet " .. sheet_name)



end

function SheetObj:load_db()
end

function SheetObj:db_save(is_timeout)
end

return SheetObj
