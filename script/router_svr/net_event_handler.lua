
function g_net_event_server_disconnect(server_id)
	
end

function g_net_event_client_disconnect(mailbox_id)
	-- get user by mailbox_id
	local user = g_user_mgr:get_user_by_mailbox(mailbox_id)
	if not user then
		return
	end

	Log.info("g_net_event_client_disconnect: user_id=%d", user._user_id)
	return g_user_mgr:offline(user)
end

function g_net_event_transfer_msg(mailbox_id, msg_id, ext)
	Log.info("g_net_event_transfer_msg: mailbox_id=%d, msg_id=%d, ext=%d", mailbox_id, msg_id, ext)
	-- TODO transfer to client or server
	-- 1. if ext is zero, its from client to server. for now, just send to user scene server
	-- 2. if ext non zero, its from server to client, ext is a role_id. so get user by role_id. check if mailbox is from a server

	if ext == 0 then
		local user = g_user_mgr:get_user_by_mailbox(mailbox_id)
		if not user then
			-- user nil 
			Log.warn("g_net_event_transfer_msg: not a user %d", mailbox_id)
			return
		end

		local scene_server_id = user._scene_server_id
		if scene_server_id == 0 then
			Log.warn("g_net_event_transfer_msg: user not in a scene server %d", user._user_id)
			return
		end
		
		local scene_server_info = g_service_mgr:get_server_by_id(scene_server_id)
		if not scene_server_info then
			Log.warn("g_net_event_transfer_msg: scene server nil %d", scene_server_id)
			return
		end

		-- add role_id into ext
		scene_server_info:transfer_msg(user._role_id)

		return
	end

	local role_id = ext
	local user = g_user_mgr:get_user_by_role_id(role_id)
	if not user then
		-- user nil 
		return
	end

	if not user:is_online() then
		return
	end

	user:transfer_msg()

end
