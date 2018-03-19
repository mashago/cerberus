
local sheet_name = "role_info"

Role = class(SheetObj)

function Role:ctor(role_id, mailbox_id)
	self._role_id = role_id
	self._mailbox_id = mailbox_id -- gate mailbox id
	self._db_save_timer_index = 0 -- > 0 means need save
end

function Role:send_msg(msg_id, msg)
	-- add role_id into ext
	return Net.send_msg_ext(self._mailbox_id, msg_id, self._role_id, msg)
end

function Role:init()
	function change_cb(...)
		Log.debug("change_cb %s", Util.table_to_string({...}))
		self:active_sync()
	end
	self:init_sheet(sheet_name, change_cb, self._role_id)
end

function Role:load_and_init_data()
	local record = self.load_data()
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

	for field_name, value in pairs(self._attr_map) do
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

function Role:active_save()
	if self._db_save_timer_index > 0 then
		return
	end

	local timer_cb = function(role)
		self._db_save_timer_index = 0
		role:db_save()
	end

	local ROLE_DB_SAVE_INTERVAL = 10000 -- ms
	self._db_save_timer_index = g_timer:add_timer(ROLE_DB_SAVE_INTERVAL, timer_cb, self, false)
end

function Role:do_sync()
	local insert_record, delete_record, modify_record = self:collect_sync_dirty()
	-- TODO
	self:send_msg(MID.ATTR_INSERT_RET)
	self:send_msg(MID.ATTR_DELETE_RET)
	self:send_msg(MID.ATTR_MODIFY_RET)
end

function Role:active_sync()
	g_role_mgr:mark_sync_role(self._role_id)
end

function Role:force_save()
	local timer_index = self._db_save_timer_index
	if timer_index == 0 then
		-- nothing change
		return
	end
	g_timer:del_timer(timer_index)
	self._db_save_timer_index = 0
	role:db_save()
end

function Role:on_disconnect()
	self:force_save()

	g_role_mgr:del_role(self)
end

g_funcs.register_getter_setter(Role, sheet_name)
