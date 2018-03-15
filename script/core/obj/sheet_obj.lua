
local SheetObj = class()

--[[
function SheetObj:ctor(sheet_name)
end
--]]

-- call by inherit class ctor
function SheetObj:init(sheet_name, change_cb, ...)
	
	self._sheet_name = sheet_name
	self._table_def = DataStructDef.data[sheet_name]
	assert(self._table_def, "SheetObj:ctor no such sheet " .. sheet_name)

	local const_keys = {...} -- {key_value1, key_value2, ...}
	assert(#const_keys > 0, "SheetObj:init key error " .. sheet_name)
	self._const_key_num = #const_keys

	self._keys = {} -- {[1]={key_id,v}, [2]={key_id,v}, ..., [n]={key_id,'_Null'}
	
	local num = 0
	for _, field_def in ipairs(self._table_def) do
		local key_index = field_def.key or 0
		if key_index ~= 0 then
			local key_value = '_Null'
			if key_index <= #const_keys then
				key_value = const_keys[key_index]
			end
			self._keys[key_index] = {field_def.id, key_value}
			num = num + 1
		end
	end
	assert(num > 0 and num == #self._keys, "SheetObj:init sheet key num error " .. sheet_name)

	Log.debug("_const_key_num=%d", self._const_key_num)
	Log.debug("_keys=%s", Util.table_to_string(self._keys))
	
	-- include const key
	-- {
	-- 		[key1] = 
	-- 		{
	-- 			[key2] = 
	-- 			{
	-- 				[keyn] = {...}
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
	self._insert_attr_map = {}
	self._delete_attr_map = {}
	self._modify_attr_map = {}

	self._change_cb = change_cb
end

function SheetObj:get_db_data()

	local conditions = {}
	for i=1, self._const_key_num do
		conditions[self._table_def[self._keys[i][1]].field] = self._keys[i][2]
	end

	local rpc_data = 
	{
		table_name = "role_info",
		fields = {},
		conditions = conditions
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
	self._root_attr_map = {}

	-- init not-db attr to default value
	local attr_map = {}

	for _, field_def in ipairs(self._table_def) do
		if field_def.save == 0 then
			local value = g_funcs.str_to_value(field_def.default, field_def.type)
			attr_map[field_def.id] = value
		end
	end

	for _, row in ipairs(db_record) do
		-- one fully attr row
		local sub_attr_map = {}
		for k, v in pairs(attr_map) do
			sub_attr_map[k] = v
		end
		for k, v in pairs(row) do
			local attr_id = self._table_def[k].id
			sub_attr_map[attr_id] = v
		end


		local absolute_pos = self._root_attr_map
		local last_key
		for i=1, #self._keys do
			if last_key then
				absolute_pos = absolute_pos[last_key]
			end
			last_key = sub_attr_map[self._keys[i][1]]
			absolute_pos[last_key] = absolute_pos[last_key] or {} 
		end
		absolute_pos[last_key] = sub_attr_map
	end

	self._attr_map = self._root_attr_map
	for i=1, self._const_key_num do
		self._attr_map = self._attr_map[self._keys[i][2]]
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

------------------------------------------------

function SheetObj:update_modify_map(key_list, attr_id)

	-- 1. modify normal row
	-- 2. modify insert row

	-- check if already in _insert_attr_map, if true, will not set in _modify_attr_map
	local is_will_insert = check_is_exists_by_key_list(self._insert_attr_map, key_list) 

	if is_will_insert then
		return
	end

	local modify_attr_map = self._modify_attr_map
	for _, key in ipairs(key_list) do
		modify_attr_map[key] = modify_attr_map[key] or {}
		modify_attr_map = modify_attr_map[key]
	end
	modify_attr_map[attr_id] = true
end

-- key_list is optional, base on _attr_map
function SheetObj:modify(attr_name, value, ...)
	
	local key_list = {...}
	-- fix key_list begin from root
	for i=1, self._const_key_num do
		table.insert(key_list, i, self._keys[i][2])
	end

	local is_will_delete = check_is_exists_by_key_list(self._delete_attr_map, key_list)
	if is_will_delete then
		Log.err("SheetObj:modify modify will delete row, sheet_name=%s key_list=%s", self._sheet_name, Util.table_to_string(key_list))
		return false
	end

	-- core logic
	local attr_id = self._table_def[attr_name].id
	local absolute_pos = self._root_attr_map
	for _, key in ipairs(key_list) do
		absolute_pos = absolute_pos[key]
	end
	absolute_pos[attr_id] = value

	self:update_modify_map(key_list, attr_id)

	if self._change_cb then
		self._change_cb()
	end

	return true
end

function SheetObj:update_insert_map(key_list, attr_data)

	-- 1. insert normal row
	-- 2. insert delete row

	-- remove from delete
	local is_will_delete = remove_by_key_list(self._delete_attr_map, key_list)

	if is_will_delete then
		-- mark data into update
		local modify_attr_map = self._modify_attr_map
		for _, key in ipairs(key_list) do
			modify_attr_map[key] = modify_attr_map[key] or {}
			modify_attr_map = modify_attr_map[key]
		end
		for k, v in pairs(attr_data) do
			modify_attr_map[k] = true
		end
	else
		-- mark into insert
		mark_by_key_list(self._insert_attr_map, key_list)
	end
end

function SheetObj:insert(data)
	local attr_data = self:convert_attr_data(data)

	-- check if duplicate, get insert position at _root_attr_map
	local is_duplicate = false
	local absolute_pos = self._root_attr_map
	local last_key
	local key_list = {}
	for _, v in ipairs(self._keys) do
		if last_key then
			absolute_pos = absolute_pos[last_key]
		end
		last_key = attr_data[v[1]]
		if not last_key then
			Log.err("SheetObj:insert key nil %s %d", self._sheet_name, v[1])
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
	absolute_pos[last_key] = attr_data

	self:update_insert_map(key_list, attr_data)

	if self._change_cb then
		self._change_cb()
	end

	return true
end

function SheetObj:update_delete_map(key_list)

	-- 1. delete normal row
	-- 2. delete modify row
	-- 3. delete insert row

	-- check if in insert or update
	local is_will_modify = remove_by_key_list(self._modify_attr_map, key_list)
	local is_will_insert = remove_by_key_list(self._insert_attr_map, key_list)
	if not is_will_insert then
		mark_by_key_list(self._delete_attr_map, key_list)
	end
end

function SheetObj:delete(...)
	
	local key_list = {...}
	-- fix key_list begin from root
	for i=1, self._const_key_num do
		table.insert(key_list, i, self._keys[i][2])
	end

	-- remove from root
	local is_exists = remove_by_key_list(self._root_attr_map, key_list)
	if not is_exists then
		Log.err("SheetObj:delete row not exists %s", Util.table_to_string(key_list))
		return false
	end

	if self._change_cb then
		self._change_cb()
	end

	self:update_delete_map(key_list)

	return true
end

function SheetObj:db_save()
end

function SheetObj:collect_dirty()
	local insert_record = {}
	Util.map2path(self._insert_attr_map, insert_record)
	local delete_record = {}
	Util.map2path(self._delete_attr_map, delete_record)
	local modify_record = {}
	Util.map2mergepath(self._modify_attr_map, modify_record)

	self._insert_attr_map = {}
	self._delete_attr_map = {}
	self._modify_attr_map = {}
	Log.info("insert_record=%s", Util.table_to_string(insert_record))
	Log.info("delete_record=%s", Util.table_to_string(delete_record))
	Log.info("modify_record=%s", Util.table_to_string(modify_record))

	-- TODO sync to role or save db
end

function SheetObj:print()
	Log.info("******* SheetObj:print %s", self._sheet_name)
	Log.info("self._root_attr_map=%s", Util.table_to_string(self._root_attr_map))
	Log.info("self._attr_map=%s", Util.table_to_string(self._attr_map))
	Log.info("self._insert_attr_map=%s", Util.table_to_string(self._insert_attr_map))
	Log.info("self._delete_attr_map=%s", Util.table_to_string(self._delete_attr_map))
	Log.info("self._modify_attr_map=%s", Util.table_to_string(self._modify_attr_map))
end

return SheetObj
