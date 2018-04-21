
function g_msg_handler.c2s_role_enter_req(data, mailbox_id)

	local user_id = data.user_id
	local token = data.token

	-- 1. check user and token
	-- 2. update user info
	-- 3. add role
	-- 4. send msg to scene

	local msg =
	{
		result = ErrorCode.SUCCESS,
	}

	-- 1. check user and token
	local user = g_user_mgr:get_user_by_id(user_id)
	if not user then
		Log.warn("c2s_role_enter_req: user not exists %d", user_id)
		msg.result = ErrorCode.ROLE_ENTER_FAIL
		Net.send_msg(mailbox_id, MID.s2c_role_enter_ret, msg)
		return
	end

	if user:is_online() then
		-- user already online
		Log.warn("c2s_role_enter_req: user already online %d", user_id)
		msg.result = ErrorCode.ROLE_ENTER_FAIL
		Net.send_msg(mailbox_id, MID.s2c_role_enter_ret, msg)
		return
	end

	local role_id = user._role_id
	local scene_id = user._scene_id
	if user._token ~= token then
		Log.warn("c2s_role_enter_req: user token mismatch %d %s %s", user_id, token, user._token)
		msg.result = ErrorCode.ROLE_ENTER_FAIL
		Net.send_msg(mailbox_id, MID.s2c_role_enter_ret, msg)
		return
	end

	local u = g_user_mgr:get_user_by_mailbox(mailbox_id)
	if u then
		Log.warn("c2s_role_enter_req: mailbox already connect to a user %d", user_id)
		msg.result = ErrorCode.ROLE_ENTER_FAIL
		Net.send_msg(mailbox_id, MID.s2c_role_enter_ret, msg)
		return
	end

	-- 2. update user info
	g_user_mgr:online(user, mailbox_id)

	local scene_server_info = nil
	if user._scene_server_id == 0 then
		scene_server_info = g_service_mgr:get_server_by_scene(scene_id)
	else
		scene_server_info = g_service_mgr:get_server_by_id(user._scene_server_id)
	end

	if not scene_server_info then
		-- TODO fix user scene to a right scene
		Log.err("c2s_role_enter_req: scene server not exists scene_id=%d", scene_id)
		msg.result = ErrorCode.ROLE_ENTER_FAIL
		Net.send_msg(mailbox_id, MID.s2c_role_enter_ret, msg)
		return
	end

	-- set when role enter success
	-- user._scene_server_id = scene_server_info._server_id
	-- Log.debug("c2s_role_enter_req: user._scene_server_id=%d", user._scene_server_id)

	-- 3. send msg to scene
	local msg =
	{
		role_id = role_id,
		scene_id = scene_id,	
	}
	scene_server_info:send_msg(MID.s2s_gate_role_enter_req, msg)

end

function g_msg_handler.s2s_gate_role_enter_ret(data, mailbox_id)
	Log.debug("s2s_gate_role_enter_ret: data=%s", Util.table_to_string(data))	
	
	local result = data.result
	local role_id = data.role_id
	local user = g_user_mgr:get_user_by_role_id(role_id)
	if not user then
		Log.warn("s2s_gate_role_enter_ret: user nil role_id=%d", role_id)
		return
	end

	local msg =
	{
		result = result,
	}

	if result ~= ErrorCode.SUCCESS then
		user:send_msg(MID.s2c_role_enter_ret, msg)
		return
	end

	local scene_server_info = g_service_mgr:get_server_by_mailbox(mailbox_id)
	if not scene_server_info then
		Log.err("s2s_gate_role_enter_ret: cannot get server_info %d", mailbox_id)
		msg.result = ErrorCode.SYS_ERROR
		user:send_msg(MID.s2c_role_enter_ret, msg)
		return
	end

	user._scene_server_id = scene_server_info._server_id

	user:send_msg(MID.s2c_role_enter_ret, msg)

end

-- transfer msg to client or server
function g_msg_handler.transfer_msg(mailbox_id, msg_id, ext)
	Log.info("g_msg_handler.transfer_msg mailbox_id=%d, msg_id=%d, ext=%d", mailbox_id, msg_id, ext)


	-- if ext is zero, its from client to server. for now, just send to user scene server
	if ext == 0 then
		local user = g_user_mgr:get_user_by_mailbox(mailbox_id)
		if not user then
			-- user nil 
			Log.warn("g_msg_handler.transfer_msg: not a user %d", mailbox_id)
			return
		end

		local scene_server_id = user._scene_server_id
		if scene_server_id == 0 then
			Log.warn("g_msg_handler.transfer_msg: user not in a scene server %d", user._user_id)
			return
		end
		
		local scene_server_info = g_service_mgr:get_server_by_id(scene_server_id)
		if not scene_server_info then
			Log.warn("g_msg_handler.transfer_msg: scene server nil %d", scene_server_id)
			return
		end

		-- add role_id into ext
		return scene_server_info:transfer_msg(user._role_id)
	end

	-- if ext non zero, its from server to client
	-- ext is a role_id, so get user by role_id. check if mailbox is from a server
	local server_info = g_service_mgr:get_server_by_mailbox(mailbox_id)
	if not server_info then
		Log.warn("g_msg_handler.transfer_msg not server msg_id=%d", msg_id)
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

	return user:transfer_msg()
end
