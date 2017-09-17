
local Role = {}

function Role:new(role_id, mailbox_id)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj._role_id = role_id
	obj._mailbox_id = mailbox_id -- router mailbox id
	obj._attr = {}

	return obj
end

function Role:send_msg(msg_id, msg)
	-- add role_id into ext
	return Net.send_msg_ext(self._mailbox_id, msg_id, self._role_id, msg)
end

function Role:load_db()
	
	local rpc_data = 
	{
		table_name = "role_info",
		fields = {},
		conditions = {role_id=role_id}
	}

	local status, ret = RpcMgr.call_by_server_type(ServerType.DB, "db_game_select", rpc_data)
	if not status then
		Log.err("Role:load_db fail")
		return false
	end

	if ret.result ~= ErrorCode.SUCCESS then
		Log.err("Role:load_db error %d", ret.result)
		return false
	end

	Log.debug("Role:load_db data=%s", Util.table_to_string(ret.data))

	if #ret.data ~= 1 then
		Log.err("Role:load_db data empty %d", ret.result)
		return false
	end

	return ret.data[1]
end

function Role:serialize_to_record()
	-- memory data to db record
	local data = {}
	-- TODO

	return data
end

function Role:init_data(record)

	local attr_map = self._attr

	-- init not-db attr to default value
	for _, field_cfg in ipairs(DataStructDef.data.role_info) do
		if field_cfg.save == 0 then
			local value = g_funcs.str_to_value(field_cfg.default, field_cfg.type)
			attr_map[field_cfg.field] = value
		end
	end

	-- init from record
	for k, v in pairs(record) do
		attr_map[k] = v
	end

	Log.debug("Role:init_data attr_map=%s", Util.table_to_string(self._attr))
end

function Role:load_and_init_data()
	local record = self:load_db()
	if not record then
		return false
	end

	self:init_data(record)

	return true
end

function Role:send_module_data()
	-- send sync == 1 or 2 attr to client

	local attr_table = g_funcs.get_empty_attr_table()
	local table_def = DataStructDef.data.role_info

	for k, v in pairs(self._attr) do
		local field_cfg = table_def[k]
		if not field_cfg then
			goto continue
		end
		if field_cfg.sync == 0 then
			goto continue
		end

		local attr_id = field_cfg.id
		local field_type = field_cfg.type
		local insert_table = nil
		if field_type == _Byte then
			insert_table = attr_table.byte_attr_list
		elseif field_type == _Bool then
			insert_table = attr_table.bool_attr_list
		elseif field_type == _Int then
			insert_table = attr_table.int_attr_list
		elseif field_type == _Float then
			insert_table = attr_table.float_attr_list
		elseif field_type == _Short then
			insert_table = attr_table.short_attr_list
		elseif field_type == _Int64 then
			insert_table = attr_table.int64_attr_list
		elseif field_type == _String then
			insert_table = attr_table.string_attr_list
		elseif field_type == _Struct then
			insert_table = attr_table.struct_attr_list
			v = Util.serialize(v)
		end
		table.insert(insert_table, {attr_id=attr_id, value=v})

		::continue::
	end
	
	Log.debug("Role:send_module_data attr_table=%s", Util.table_to_string(attr_table))
	
	local msg =
	{
		role_id = self._role_id,
		attr_table = attr_table,
	}
	self:send_msg(MID.ROLE_ATTR_RET, msg)
end

return Role
