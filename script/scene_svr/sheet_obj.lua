
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

	self._keys = {} -- {[1]={key_name1,v}, [2]={key_name2,v}, ..., [n]={key_namen,'_Null'}
	
	local num = 0
	for _, field_def in ipairs(self._table_def) do
		local key_index = field_def.key or 0
		if key_index ~= 0 then
			local key_value = '_Null'
			if key_index <= #const_keys then
				key_value = const_keys[key_index]
			end
			self._keys[key_index] = {field_def.field, key_value}
			num = num + 1
		end
	end
	assert(num > 0 and num == #self._keys, "SheetObj:init sheet key num error " .. sheet_name)
	
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
	self._delete_attr_map = {}
	self._insert_attr_map = {}
	self._modify_attr_map = {}

	self._change_cb = change_cb
end

function SheetObj:get_db_data()

	local conditions = {}
	for i=1, self._const_key_num do
		conditions[self._keys[i][1]] = self._keys[i][2]
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
			last_key = sub_attr_map[self._keys[i][1]]
			absolute_pos[last_key] = absolute_pos[last_key] or {} 
		end
		absolute_pos[last_key] = sub_attr_map
	end

	local self._attr_map = self._root_attr_map
	for i=1, self._const_key_num do
		self._attr_map = self._attr_map[self._keys[i][2]]
	end

end

-- key_list is optional, base on _attr_map
function SheetObj:modify(attr_name, value, ...)
	
	local key_list = {...}
	-- fix key_list begin from root
	for i=1, self._const_key_num do
		table.insert(key_list, i, self._keys[i][2])
	end

	local absolute_pos = self._root_attr_map
	local modify_attr_map = self._modify_attr_map
	local insert_attr_map = self._insert_attr_map
	local delete_attr_map = self._delete_attr_map

	local is_will_delete = true
	for _, key in ipairs(key_list) do
		delete_attr_map = delete_attr_map[key]
		if not delete_attr_map or not next(delete_attr_map) then
			is_will_delete = false
			break
		end
	end
	if is_will_delete then
		Log.err("SheetObj:modify modify will delete row, sheet_name=%s key_list=%s", self._sheet_name, Util.table_to_string(key_list))
		return false
	end


	-- check if already in _insert_attr_map, if true, will not set in _modify_attr_map
	local is_will_insert = true 
	for _, key in ipairs(key_list) do
		insert_attr_map = insert_attr_map[key]
		if not insert_attr_map then
			is_will_insert = false
			break
		end
	end

	if is_will_insert then
		for _, key in ipairs(key_list) do
			absolute_pos = absolute_pos[key]
		end
		absolute_pos[attr_name] = value
	else
		for _, key in ipairs(key_list) do
			absolute_pos = absolute_pos[key]
			modify_attr_map[key] = modify_attr_map[key] or {}
			modify_attr_map = modify_attr_map[key]
		end
		absolute_pos[attr_name] = value
		modify_attr_map[attr_name] = true
	end

	self._change_cb()

	return true
end

function SheetObj:insert(data)
	-- check if duplicate
	local is_duplicate = false
	local absolute_pos = self._root_attr_map
	local last_key
	local key_list = {}
	for _, v in ipairs(self._keys) do
		if last_key then
			absolute_pos = absolute_pos[last_key]
		end
		last_key = data[v[1]]
		absolute_pos[last_key] = absolute_pos[last_key] or {}
		table.insert(key_list, last_key)
	end

	if next(absolute_pos[last_key]) then
		Log.err("SheetObj:insert duplicate key %s", self._sheet_name)
		return false
	end

	-- core logic
	absolute_pos[last_key] = data

	-- check if will delete, if true, remove delete, add full update
	local delete_pos = self._delete_attr_map
	local is_will_delete = true
	local last_key
	for i, key in ipairs(key_list) do
		if last_key then
			delete_pos = delete_pos[last_key]
		end

		if not delete_pos[key] then
			is_will_delete = false
			break
		end

		if not next(delete_pos[key]) then
			is_will_delete = false
			delete_pos[key] = nil
			break
		end
		last_key = key
	end
	if is_will_delete then
		-- remove from delete
		delete_pos[last_key] = nil

		-- set into update
		local modify_attr_map = self._modify_attr_map
		for _, key in ipairs(key_list) do
			modify_attr_map[key] = modify_attr_map[key] or {}
			modify_attr_map = modify_attr_map[key]
		end
		for k, v in pairs(data) do
			modify_attr_map[k] = true
		end
	else
		-- set into insert
		local insert_pos = self._insert_attr_map
		for i, key in ipairs(key_list) do
			if i ~= #key_list then
				insert_pos[key] = insert_pos[key] or {}
				insert_pos = insert_pos[key]
			else
				insert_pos[key] = true
			end
		end
	end


	return true
end

function SheetObj:delete(...)
	return true
end

function SheetObj:db_save()
end

return SheetObj
