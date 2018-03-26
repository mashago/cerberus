
local UserMgr = class()

function UserMgr:ctor()
	self._all_user_map = {} -- {[user_id]=[User], }
	self._all_user_num = 0

	self._mailbox_user_map = {} -- {[mailbox_id]=[User], }
	self._role_user_map = {} -- {[role_id]=[User], }

	self._offline_user_map = {} -- {[user_id]=timer_index,}
end

function UserMgr:connect_timeout_cb(user_id)
	Log.debug("UserMgr:offline_timer_cb delete offline user %d", user_id)
	self._offline_user_map[user_id] = nil
	local user = self:get_user_by_id(user_id)
	self:del_user(user)

	-- TODO rpc to bridge
end

function UserMgr:add_user(user)

	if self._all_user_map[user._user_id] then
		-- duplicate login
		return false
	end

	self._all_user_map[user._user_id] = user
	self._all_user_num = self._all_user_num + 1 
	self._role_user_map[user._role_id] = user
	local connect_wait_interval_ms = 10 * 1000
	local timer_cb = function(user_id)
		self:connect_timeout_cb(user_id)
	end
	self._offline_user_map[user._user_id] = g_timer:add_timer(connect_wait_interval_ms, timer_cb, user._user_id, false)
	return true
end

function UserMgr:kick_user(user)
	Log.warn("UserMgr:kick_user user_id=%d role_id=%d", user._user_id, user._role_id)

	user:send_msg(MID.ROLE_KICK_MSG, {reason = 1})
	
	self:offline(user)

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
	self._all_user_num = self._all_user_num - 1 

	-- self._mailbox_user_map[user._mailbox_id] = nil
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
		g_timer:del_timer(timer_index)
		self._offline_user_map[user_id] = nil
	end
end

function UserMgr:offline_timer_cb(user_id)
	Log.debug("UserMgr:offline_timer_cb delete offline user %d", user_id)
	self._offline_user_map[user_id] = nil
	local user = self:get_user_by_id(user_id)
	self:del_user(user)
end

function UserMgr:offline(user)
	local user_id = user._user_id
	self._mailbox_user_map[user._mailbox_id] = nil
	user:offline()

	-- add timer to delete user
	local delete_user_interval_ms = 300 * 1000
	-- local delete_user_interval_ms = 10 * 1000
	local timer_cb = function(user_id)
		self:offline_timer_cb(user_id)
	end
	self._offline_user_map[user_id] = g_timer:add_timer(delete_user_interval_ms, timer_cb, user_id, false)

end

return UserMgr
