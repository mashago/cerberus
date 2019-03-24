
local Core = require "core"
local class = require "util.class"
local RoleMgr = class()

function RoleMgr:ctor()
	self._all_role_map = {} -- {[role_id]=[role], }
	self._mailbox_role_map = {} -- gate_mailbox_id to role_id map {[mailbox_id]={role_id=true, role_id=true}, } -- 

	self._sync_role_timer_index = 0
	self._sync_role_map = {} -- role_id
	self._save_role_map = {} -- role_id
end

function RoleMgr:add_role(role)

	if self._all_role_map[role._role_id] then
		-- duplicate add
		return false
	end

	self._all_role_map[role._role_id] = role

	self._mailbox_role_map[role._mailbox_id] = self._mailbox_role_map[role._mailbox_id] or {}
	self._mailbox_role_map[role._mailbox_id][role._role_id] = true
	return true
end

function RoleMgr:get_role_by_id(role_id)
	return self._all_role_map[role_id]
end

function RoleMgr:del_role(role)
	self._all_role_map[role._role_id] = nil
	self._mailbox_role_map[role._mailbox_id][role._role_id] = nil
	role._mailbox_id = 0
end

function RoleMgr:sync_all_role()
	for role_id, _ in pairs(self._sync_role_map) do
		local role = self:get_role_by_id(role_id)
		if role then
			role:sync_dirty()
		end
	end
	self._sync_role_map = {}
end

function RoleMgr:mark_sync_role(role_id)
	self._sync_role_map[role_id] = true
	if self._sync_role_timer_index ~= 0 then
		return
	end
	local timer_cb = function()
		self._sync_role_timer_index = 0
		self:sync_all_role()
	end
	local ROLE_SYNC_INTERVAL = 500 -- ms
	self._sync_role_timer_index = Core.timer_mgr:add_timer(ROLE_SYNC_INTERVAL, timer_cb, self, false)

end

function RoleMgr:mark_save_role(role_id)
	self._save_role_map[role_id] = true
end

function RoleMgr:unmark_save_role(role_id)
	self._save_role_map[role_id] = nil
end

function RoleMgr:force_save_all_role()
	for role_id, _ in pairs(self._save_role_map) do
		local role = self:get_role_by_id(role_id)
		if role then
			role:force_save()
		end
	end
	self._save_role_map = {}
end

return RoleMgr
