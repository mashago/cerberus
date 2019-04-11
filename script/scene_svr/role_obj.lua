
local timer_mgr = require "timer.timer"
local net_mgr = require "net.net_mgr"
local class = require "util.class"
local g_funcs = require "global.global_funcs"
local SheetObj = require "obj.sheet_obj"
local SHEET_NAME = "role_info"
local msg_def = require "global.net_msg_def"
local MID = msg_def.MID
local Env = require "env"

local Role = class(SheetObj)


function Role:ctor(role_id, mailbox_id)
	self._role_id = role_id
	self._mailbox_id = mailbox_id -- gate mailbox id
	self._db_save_timer_index = 0 -- > 0 means need save
end

function Role:send_msg(msg_id, msg)
	-- add role_id into ext
	return net_mgr:send_msg_ext(self._mailbox_id, msg_id, self._role_id, msg)
end

function Role:init()
	self:init_sheet(SHEET_NAME, {self._role_id})
end

function Role:load_and_init_data()
	local record = self:load_data()
	if not record then
		return false
	end
	self:init_data(record)
	return true
end

function Role:send_module_data()
	-- send sync == 1 or 2 attr to client

	local rows = self:get_sync_attr_table()
	local msg =
	{
		sheet_name = self._sheet_name,
		rows = rows,
	}
	self:send_msg(MID.s2c_attr_info_ret, msg)
end

function Role:modify_attr_table(attr_table)
	
	local attr_map = g_funcs.attr_table_to_attr_map(self._table_def, attr_table)
	-- Log.debug("Role:modify_attr_table attr_map=%s", Util.table_to_string(attr_map))

	for k, v in pairs(attr_map) do
		local func_name = "set_" .. k
		if self[func_name] then
			self["set_" .. k](self, v)
		end
	end

	--[[
	local msg =
	{
		role_id = self._role_id,
		attr_table = attr_table,
	}
	self:send_msg(MID.s2c_role_attr_change_ret, msg)
	--]]
end


function Role:force_save()
	local timer_index = self._db_save_timer_index
	if timer_index == 0 then
		-- nothing change
		return
	end
	Env.role_mgr:unmark_save_role(self._role_id)
	timer_mgr:del_timer(timer_index)
	self._db_save_timer_index = 0
	self:save_dirty()
end

function Role:on_disconnect()
	self:force_save()
	Env.role_mgr:del_role(self)
end

-------------------------------------------
-- call by sheet_obj
function Role:active_sync()
	Env.role_mgr:mark_sync_role(self._role_id)
end

function Role:do_sync(insert_rows, delete_rows, modify_rows)
	-- self:send_msg(MID.s2c_attr_insert_ret)
	-- self:send_msg(MID.s2c_attr_delete_ret)

	self:send_msg(MID.s2c_attr_modify_ret,
	{
		sheet_name = self._sheet_name,
		rows = modify_rows,
	})
end

function Role:active_save()
	if self._db_save_timer_index > 0 then
		return
	end
	Env.role_mgr:mark_save_role(self._role_id)

	local timer_cb = function(role)
		Env.role_mgr:unmark_save_role(self._role_id)
		self._db_save_timer_index = 0
		role:save_dirty()
	end

	local ROLE_DB_SAVE_INTERVAL = 10000 -- ms
	self._db_save_timer_index = timer_mgr:add_timer(ROLE_DB_SAVE_INTERVAL, timer_cb, self, false)
end

---------------------------------------

g_funcs.register_getter_setter(Role, SHEET_NAME)

return Role
