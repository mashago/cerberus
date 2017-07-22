
local RoleMgr = {}

function RoleMgr:new()
	local obj = {}
	self.__index = self
	setmetatable(obj, self)

	obj._all_role_map = {} -- {[role_id]=[role], }
	obj._mailbox_role_map = {} -- {[mailbox_id]=[role], }

	return obj	
end

function RoleMgr:add_role(role)

	if self._all_role_map[role._role_id] then
		-- duplicate login
		return false
	end

	self._all_role_map[role._role_id] = role
	self._mailbox_role_map[role._mailbox_id] = role
	return true
end

function RoleMgr:get_role_by_id(role_id)
	return self._all_role_map[role_id]
end

function RoleMgr:get_role_by_mailbox(mailbox_id)
	return self._mailbox_role_map[mailbox_id]
end

function RoleMgr:del_role(role)
	self._all_role_map[role._role_id] = nil
	self._mailbox_role_map[role._mailbox_id] = nil
end

return RoleMgr
