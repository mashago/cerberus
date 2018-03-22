
SheetObj = class()

--[[
function SheetObj:ctor(sheet_name)
end
--]]

function SheetObj:init_sheet(sheet_name, const_keys, change_cb, sync_func, save_func)
	
	self._sheet_name = sheet_name
	self._table_def = DataStructDef.data[sheet_name]
	assert(self._table_def, "SheetObj:ctor no such sheet " .. sheet_name)

	assert(#const_keys > 0, "SheetObj:init_sheet key error " .. sheet_name)
	self._const_key_num = #const_keys

	self._keys = {} -- {[1]={key_id, key_name, v}, [2]={key_id, key_name, v}, ..., [n]={key_id, key_name, '_Null'}
	
	local num = 0
	for _, field_def in ipairs(self._table_def) do
		local key_index = field_def.key or 0
		if key_index ~= 0 then
			local key_value = '_Null'
			if key_index <= #const_keys then
				key_value = const_keys[key_index]
			end
			self._keys[key_index] = {field_def.id, field_def.field, key_value}
			num = num + 1
		end
	end

	Log.debug("_const_key_num=%d", self._const_key_num)
	Log.debug("_keys=%s", Util.table_to_string(self._keys))

	self._change_cb = change_cb
	self._sync_func = sync_func
	self._save_func = save_func
	
	-- include const key
	-- {
	-- 		[key1] = 
	-- 		{
	-- 			[key2] = 
	-- 			{
	-- 				[keyn] =
	-- 				{
	-- 					k = v,
	-- 				}
	-- 				[keyn] = {...}
	-- 			}
	-- 		}
	-- }
	self._root_attr_map = {}

	-- no const key
	-- {
	-- 		attr_a = n,
	-- 		attr_b = n,
	-- 	}
	-- 	or
	-- 	{
	-- 		[keyn] = {...},
	-- 		[keyn] = {...},
	-- 	}
	self._attr_map = {}

	-- base on _root_attr_map
	self._sync_insert_attr_map = {}
	self._sync_delete_attr_map = {}
	self._sync_modify_attr_map = {} -- mark by attr_id

	self._db_insert_attr_map = {}
	self._db_delete_attr_map = {}
	self._db_modify_attr_map = {} -- mark by attr_id
end

function SheetObj:load_data()

	local conditions = {}
	for i=1, self._const_key_num do
		conditions[self._keys[i][2]] = self._keys[i][3]
	end

	local rpc_data = 
	{
		table_name = "role_info",
		fields = {},
		conditions = conditions
	}

	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_game_select", rpc_data, self._key)
	if not status then
		Log.err("SheetObj:load_data fail")
		return false
	end

	if ret.result ~= ErrorCode.SUCCESS then
		Log.err("SheetObj:load_data error %d", ret.result)
		return false
	end

	return ret.data
end

function SheetObj:init_data(db_record)
	self._root_attr_map = {}

	-- init not-db attr to default value
	local attr_map = {}

	for _, field_def in ipairs(self._table_def) do
		if field_def.save == 0 then
			local value = g_funcs.str_to_value(field_def.default, field_def.type)
			attr_map[field_def.field] = value
		end
	end

	for _, row in ipairs(db_record) do
		-- one fully attr row
		local sub_attr_map = {}
		for k, v in pairs(attr_map) do
			sub_attr_map[k] = v
		end
		for k, v in pairs(row) do
			sub_attr_map[k] = v
		end

		local absolute_pos = self._root_attr_map
		local last_key
		for i=1, #self._keys do
			if last_key then
				absolute_pos = absolute_pos[last_key]
			end
			last_key = sub_attr_map[self._keys[i][2]]
			absolute_pos[last_key] = absolute_pos[last_key] or {} 
		end
		absolute_pos[last_key] = sub_attr_map
	end

	self._attr_map = self._root_attr_map
	for i=1, self._const_key_num do
		self._attr_map = self._attr_map[self._keys[i][3]]
	end

end

---------------------------------------

-- key_list = {key1, key2, key3, ...}
local function check_is_exists_by_key_list(t, key_list)
	local is_marked = true
	for k, v in ipairs(key_list) do
		if not t or not t[v] then
			is_marked = false
			break
		end
		t = t[v]
	end

	return is_marked
end

local function remove_by_key_list(t, key_list)
	local is_exists = false

	for k, v in ipairs(key_list) do
		if not t or not t[v] then
			break
		end
		if k == #key_list then
			t[v] = nil
			is_exists = true
			break
		end
		t = t[v]
	end

	return is_exists
end

-- mark as true
-- key table will create if not exists
local function mark_by_key_list(t, key_list)
	for k, v in ipairs(key_list) do
		if k == #key_list then
			t[v] = true
			break
		end
		t[v] = t[v] or {}
		t = t[v]
	end
end

--[[
{
	[attr_name1] = n,
	[attr_name2] = n,
}
==>
{
	[attr_id1] = n,
	[attr_id2] = n,
}

--]]
function SheetObj:convert_attr_data(data)
	local attr_data = {}
	for k, v in pairs(data) do
		local field_def = self._table_def[k]
		if field_def then
			attr_data[field_def.id] = v
		end
	end
	return attr_data
end

function SheetObj:get_fix_key_list(...)
	local key_list = {...}
	-- fix key_list begin from root
	for i=1, self._const_key_num do
		table.insert(key_list, i, self._keys[i][3])
	end
	return key_list
end

function SheetObj:get_attr(attr_name, ...)
	local key_list = self:get_fix_key_list(...)

	local target = self._root_attr_map
	for _, key in ipairs(key_list) do
		target = target[key]
	end
	return target[attr_name]
end

------------------------------------------------

function SheetObj:update_modify_map(insert_map, delete_map, modify_map, key_list, attr_id, check_flag)

	local flag = self._table_def[attr_id][check_flag]
	if not flag or flag == 0 then
		return
	end

	-- 1. modify normal row
	-- 2. modify insert row

	-- check if already in insert_map, if true, will not set in modify_map
	local is_will_insert = check_is_exists_by_key_list(insert_map, key_list) 

	if is_will_insert then
		return
	end

	local target_map = modify_map
	for _, key in ipairs(key_list) do
		target_map[key] = target_map[key] or {}
		target_map = target_map[key]
	end
	target_map[attr_id] = true
end

-- ... is key_list, base on _attr_map
function SheetObj:modify(attr_name, value, ...)
	
	local key_list = self:get_fix_key_list(...)

	local is_will_delete = check_is_exists_by_key_list(self._sync_delete_attr_map, key_list)
	if is_will_delete then
		Log.err("SheetObj:modify modify will delete row, sheet_name=%s key_list=%s", self._sheet_name, Util.table_to_string(key_list))
		return false
	end

	-- core logic
	local absolute_pos = self._root_attr_map
	for _, key in ipairs(key_list) do
		absolute_pos = absolute_pos[key]
	end
	absolute_pos[attr_name] = value

	local attr_id = self._table_def[attr_name].id
	self:update_modify_map(self._sync_insert_attr_map, self._sync_delete_attr_map, self._sync_modify_attr_map, key_list, attr_id, "sync")
	self:update_modify_map(self._db_insert_attr_map, self._db_delete_attr_map, self._db_modify_attr_map, key_list, attr_id, "save")

	if self._change_cb then
		self._change_cb()
	end

	return true
end

function SheetObj:update_insert_map(insert_map, delete_map, modify_map, key_list, attr_data, check_flag)

	-- 1. insert normal row
	-- 2. insert delete row

	-- remove from delete
	local is_will_delete = remove_by_key_list(delete_map, key_list)

	if is_will_delete then
		-- mark data into update
		local target_map = modify_map
		for _, key in ipairs(key_list) do
			target_map[key] = target_map[key] or {}
			target_map = target_map[key]
		end
		for attr_id, v in pairs(attr_data) do
			local flag = self._table_def[attr_id][check_flag]
			local key = self._table_def[attr_id].key or 0
			if flag and flag ~= 0 and key == 0 then
				target_map[attr_id] = true
			end
		end
	else
		-- mark into insert
		mark_by_key_list(insert_map, key_list)
	end

end

function SheetObj:insert(data)

	-- check if duplicate, get insert position at _root_attr_map
	local is_duplicate = false
	local absolute_pos = self._root_attr_map
	local last_key
	local key_list = {}
	for _, v in ipairs(self._keys) do
		if last_key then
			absolute_pos = absolute_pos[last_key]
		end
		last_key = data[v[2]]
		if not last_key then
			Log.err("SheetObj:insert key nil %s %s", self._sheet_name, v[2])
			return false
		end
		absolute_pos[last_key] = absolute_pos[last_key] or {}
		table.insert(key_list, last_key)
	end

	if next(absolute_pos[last_key]) then
		Log.err("SheetObj:insert duplicate key %s", self._sheet_name)
		return false
	end

	-- TODO set default attr by table_def

	-- core logic
	absolute_pos[last_key] = data

	local attr_data = self:convert_attr_data(data)
	self:update_insert_map(self._sync_insert_attr_map, self._sync_delete_attr_map, self._sync_modify_attr_map, key_list, attr_data, "sync")
	self:update_insert_map(self._db_insert_attr_map, self._db_delete_attr_map, self._db_modify_attr_map, key_list, attr_data, "save")

	if self._change_cb then
		self._change_cb()
	end

	return true
end

function SheetObj:update_delete_map(insert_map, delete_map, modify_map, key_list)

	-- 1. delete normal row
	-- 2. delete modify row
	-- 3. delete insert row

	-- check if in insert or update
	local is_will_modify = remove_by_key_list(modify_map, key_list)
	local is_will_insert = remove_by_key_list(insert_map, key_list)
	if not is_will_insert then
		mark_by_key_list(delete_map, key_list)
	end
end

-- ... is key_list, base on _attr_map
function SheetObj:delete(...)
	
	local key_list = self:get_fix_key_list(...)

	-- remove from root
	local is_exists = remove_by_key_list(self._root_attr_map, key_list)
	if not is_exists then
		Log.err("SheetObj:delete row not exists %s", Util.table_to_string(key_list))
		return false
	end

	self:update_delete_map(self._sync_insert_attr_map, self._sync_delete_attr_map, self._sync_modify_attr_map, key_list)
	self:update_delete_map(self._db_insert_attr_map, self._db_delete_attr_map, self._db_modify_attr_map, key_list)

	if self._change_cb then
		self._change_cb()
	end

	return true
end

function SheetObj:collect_sync_dirty()
	Log.info("SheetObj:collect_sync_dirty()")
	local insert_record = {}
	Util.map2path(self._sync_insert_attr_map, insert_record)
	local delete_record = {}
	Util.map2path(self._sync_delete_attr_map, delete_record)
	local modify_record = {}
	Util.map2mergepath(self._sync_modify_attr_map, modify_record)

	self._sync_insert_attr_map = {}
	self._sync_delete_attr_map = {}
	self._sync_modify_attr_map = {}
	-- Log.info("insert_record=%s", Util.table_to_string(insert_record))
	-- Log.info("delete_record=%s", Util.table_to_string(delete_record))
	-- Log.info("modify_record=%s", Util.table_to_string(modify_record))

	return insert_record, delete_record, modify_record
end

function SheetObj:collect_save_dirty()
	Log.info("SheetObj:collect_save_dirty()")
	local insert_record = {}
	Util.map2path(self._db_insert_attr_map, insert_record)
	local delete_record = {}
	Util.map2path(self._db_delete_attr_map, delete_record)
	local modify_record = {}
	Util.map2mergepath(self._db_modify_attr_map, modify_record)

	self._db_insert_attr_map = {}
	self._db_delete_attr_map = {}
	self._db_modify_attr_map = {}
	Log.info("insert_record=%s", Util.table_to_string(insert_record))
	Log.info("delete_record=%s", Util.table_to_string(delete_record))
	Log.info("modify_record=%s", Util.table_to_string(modify_record))

	return insert_record, delete_record, modify_record
end

function SheetObj:convert_sync_insert_rows(insert_record)
	local ret = {}
	for _, line in ipairs(insert_record) do
		local attrs = g_funcs.get_empty_attr_table()
		local row = self._root_attr_map
		for i, node in ipairs(line) do
			row = row[node]
		end
		for k, v in pairs(row) do
			if self._table_def[k].sync and self._table_def[k].sync ~= 0 then
				g_funcs.set_attr_table(attrs, self._table_def, k, v)
			end
		end
		table.insert(ret, attrs)
	end
	return ret
end

function SheetObj:convert_sync_delete_rows(delete_record)
	local ret = {}
	for _, line in ipairs(delete_record) do
		local keys = g_funcs.get_empty_attr_table()
		for i, node in ipairs(line) do
			local key_info = self._keys[i]
			g_funcs.set_attr_table(keys, self._table_def, key_info[2], node)
		end
		table.insert(ret, keys)
	end
	return ret
end

function SheetObj:convert_sync_modify_rows(modify_record)
	local ret = {}
	for _, line in ipairs(modify_record) do
		local keys = g_funcs.get_empty_attr_table()
		local attrs = g_funcs.get_empty_attr_table()
		local row = self._root_attr_map
		for i, node in ipairs(line) do
			if type(node) ~= 'table' then
				-- is key
				local key_info = self._keys[i]
				g_funcs.set_attr_table(keys, self._table_def, key_info[2], node)
				row = row[node]
			else
				-- is modify attr name list
				for __, attr_id in ipairs(node) do
					local attr_name = self._table_def[attr_id].field
					g_funcs.set_attr_table(attrs, self._table_def, attr_name, row[attr_name])
				end
			end
		end
		table.insert(ret,
		{
			keys = keys,
			attrs = attrs,
		})
	end
	return ret
end

function SheetObj:convert_save_insert_rows(insert_record)
	-- TODO
	return {}
end

function SheetObj:convert_save_delete_rows(delete_record)
	-- TODO
	return {}
end

function SheetObj:convert_save_modify_rows(modify_record)
	-- TODO
	return {}
end

function SheetObj:sync_dirty()
	local insert_record, delete_record, modify_record = self:collect_sync_dirty()
	local insert_rows = self:convert_sync_insert_rows(insert_record)
	local delete_rows = self:convert_sync_delete_rows(delete_record)
	local modify_rows = self:convert_sync_modify_rows(modify_record)
	if self._sync_func then
		self._sync_func(insert_rows, delete_rows, modify_rows)
	end
end

function SheetObj:save_dirty()
	local insert_record, delete_record, modify_record = self:collect_save_dirty()
	local insert_rows = self:convert_save_insert_rows(insert_record)
	local delete_rows = self:convert_save_delete_rows(delete_record)
	local modify_rows = self:convert_save_modify_rows(modify_record)
	if self._save_func then
		self._save_func(insert_rows, delete_rows, modify_rows)
	end
end

function SheetObj:print()
	Log.info("******* SheetObj:print %s", self._sheet_name)
	Log.info("self._root_attr_map=%s", Util.table_to_string(self._root_attr_map))
	Log.info("self._sync_insert_attr_map=%s", Util.table_to_string(self._sync_insert_attr_map))
	Log.info("self._sync_delete_attr_map=%s", Util.table_to_string(self._sync_delete_attr_map))
	Log.info("self._sync_modify_attr_map=%s", Util.table_to_string(self._sync_modify_attr_map))
	Log.info("self._db_insert_attr_map=%s", Util.table_to_string(self._db_insert_attr_map))
	Log.info("self._db_delete_attr_map=%s", Util.table_to_string(self._db_delete_attr_map))
	Log.info("self._db_modify_attr_map=%s", Util.table_to_string(self._db_modify_attr_map))
end

return SheetObj
