
UserMgr = {}

UserMgr._all_user_map = {} -- {[user_id]=[User], }
UserMgr._mailbox_user_map = {} -- {[mailbox_id]=[User], }

function UserMgr.add_user(user)

	if UserMgr._all_user_map[user._user_id] then
		-- duplicate login
		return false
	end

	if UserMgr._mailbox_user_map[user._mailbox_id] then
		-- duplicate login
		return false
	end

	UserMgr._all_user_map[user._user_id] = user
	UserMgr._mailbox_user_map[user._mailbox_id] = user
	return true
end

function UserMgr.get_user_by_mailbox(mailbox_id)
	return UserMgr._mailbox_user_map[mailbox_id]
end

function UserMgr.del_user(user)
	UserMgr._all_user_map[user._user_id] = nil
	UserMgr._mailbox_user_map[user._mailbox_id] = nil
	user._is_online = false
end

return UserMgr
