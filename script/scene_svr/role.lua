
local Role = class()

function Role:ctor(role_id, mailbox_id)
	self._role_id = role_id
	self._mailbox_id = mailbox_id -- router mailbox id
	self._attr = {} -- {pos_x = 1, pos_y = 2, ...}

	-- mark the attr need to save into db
	self._db_save_timer_index = 0 -- > 0 means need save
	self._db_change_attr = {} -- {attr_name = value, ...}
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
		conditions = {role_id=self._role_id}
	}

	local status, ret = g_rpc_mgr:call_by_server_type(ServerType.DB, "db_game_select", rpc_data, self._role_id)
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
	for _, field_def in ipairs(DataStructDef.data.role_info) do
		if field_def.save == 0 then
			local value = g_funcs.str_to_value(field_def.default, field_def.type)
			attr_map[field_def.field] = value
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

	local out_attr_table = g_funcs.get_empty_attr_table()
	local table_def = DataStructDef.data.role_info

	for field_name, value in pairs(self._attr) do
		local field_def = table_def[field_name]
		if not field_def then
			goto continue
		end
		if field_def.sync == 0 then
			goto continue
		end

		g_funcs.set_attr_table(out_attr_table, table_def, field_name, value)
		::continue::
	end
	
	Log.debug("Role:send_module_data out_attr_table=%s", Util.table_to_string(out_attr_table))
	
	local msg =
	{
		role_id = self._role_id,
		attr_table = out_attr_table,
	}
	self:send_msg(MID.ROLE_ATTR_RET, msg)
end

function Role:db_save(is_timeout)
	local timer_index = self._db_save_timer_index
	if timer_index == 0 then
		-- nothing change
		return
	end

	if not is_timeout then
		-- not timeout, may cause by role disconnect, must delete save db timer
		g_timer:del_timer(timer_index)
	end
	self._db_save_timer_index = 0

	local rpc_data = 
	{
		table_name = "role_info",
		fields = self._db_change_attr,
		conditions = {role_id=self._role_id}
	}
	g_rpc_mgr:call_nocb_by_server_type(ServerType.DB, "db_game_update", rpc_data, self._role_id)

	self._db_change_attr = {}
end

function Role:active_save_db()
	if self._db_save_timer_index > 0 then
		return
	end

	local timer_cb = function(role)
		role:db_save(true)
	end

	local ROLE_DB_SAVE_INTERVAL = 10000 -- ms
	self._db_save_timer_index = g_timer:add_timer(ROLE_DB_SAVE_INTERVAL, timer_cb, self, false)
end

function Role:modify_attr(attr_name, value)

	self._attr[attr_name] = value

	-- save to _change_attr, for update to db
	local table_def = DataStructDef.data.role_info
	local field_def = table_def[attr_name]
	if not field_def then
		return
	end

	if field_def.save ~= 1 then
		-- no need save to db
		return
	end

	self._db_change_attr[attr_name] = value
	self:active_save_db()
end

function Role:modify_attr_table(attr_table)
	
	local table_def = DataStructDef.data.role_info
	local attr_map = g_funcs.attr_table_to_attr_map(table_def, attr_table)
	Log.debug("Role:modify_attr_table attr_map=%s", Util.table_to_string(attr_map))

	for k, v in pairs(attr_map) do
		self:modify_attr(k, v)
	end

	local msg =
	{
		role_id = self._role_id,
		attr_table = attr_table,
	}
	self:send_msg(MID.ROLE_ATTR_CHANGE_RET, msg)
end

function Role:on_disconnect()
	-- save db
	self:db_save(false)

	g_role_mgr:del_role(self)
end

return Role
