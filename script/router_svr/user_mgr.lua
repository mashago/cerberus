
local UserMgr = {}

function UserMgr:new()
	local obj = {}
	self.__index = self
	setmetatable(obj, self)

	obj._all_user_map = {} -- {[user_id]=[User], }
	obj._mailbox_user_map = {} -- {[mailbox_id]=[User], }
	obj._role_user_map = {} -- {[role_id]=[User], }

	obj._offline_user_map = {} -- {[user_id]=timer_index,}

	return obj	
end

function UserMgr:add_user(user)

	if self._all_user_map[user._user_id] then
		-- duplicate login
		return false
	end

	self._all_user_map[user._user_id] = user
	self._role_user_map[user._role_id] = user
	return true
end

function UserMgr:get_user_by_id(user_id)
	return self._all_user_map[user_id]
end

function UserMgr:get_user_by_mailbox(mailbox_id)
	return self._mailbox_user_map[mailbox_id]
end

function UserMgr:get_user_by_role_id(role_id)
	return self._role_user_map[role_id]
end

function UserMgr:del_user(user)
	self._all_user_map[user._user_id] = nil
	self._mailbox_user_map[user._mailbox_id] = nil
	self._role_user_map[user._role_id] = nil
	user._mailbox_id = 0
end

function UserMgr:online(user, mailbox_id)
	self._mailbox_user_map[mailbox_id] = user
	user._mailbox_id = mailbox_id

	local user_id = user._user_id
	-- re-online user, remove timer
	local timer_index = self._offline_user_map[user_id]
	if timer_index then
		Timer.del_timer(timer_index)
		self._offline_user_map[user_id] = nil
	end
end

function UserMgr:offline(user)
	self._mailbox_user_map[user._mailbox_id] = nil
	user:offline()
	-- add timer to delete user
	local delete_user_interval_ms = 30 * 1000
	local timer_cb = function(user_id)
		Log.debug("UserMgr:offline delete offline user %d", user_id)
		self._offline_user_map[user_id] = nil
		local user = self:get_user_by_id(user_id)
		self:del_user(user)
	end
	local timer_index = Timer.add_timer(delete_user_interval_ms, timer_cb, user._user_id, false)

end

return UserMgr
