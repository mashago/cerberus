
local RoleMgr = class()

function RoleMgr:ctor()
	self._all_role_map = {} -- {[role_id]=[role], }
	self._mailbox_role_map = {} -- gate_mailbox_id to role_id map {[mailbox_id]={role_id=true, role_id=true}, } -- 
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

return RoleMgr
