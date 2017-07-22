
local function handle_role_enter(data, mailbox_id)

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
		Log.warn("handle_role_enter: user not exists %d", user_id)
		msg.result = ErrorCode.ROLE_ENTER_FAIL
		Net.send_msg(mailbox_id, MID.ROLE_ENTER_RET, msg)
		return
	end

	local role_id = user._role_id
	local scene_id = user._scene_id
	if user._token ~= token then
		Log.warn("handle_role_enter: user token mismatch %d %s %s", user_id, token, user._token)
		msg.result = ErrorCode.ROLE_ENTER_FAIL
		Net.send_msg(mailbox_id, MID.ROLE_ENTER_RET, msg)
		return
	end

	local u = g_user_mgr:get_user_by_mailbox(mailbox_id)
	if u then
		Log.warn("handle_role_enter: mailbox already connect to a user %d", user_id)
		msg.result = ErrorCode.ROLE_ENTER_FAIL
		Net.send_msg(mailbox_id, MID.ROLE_ENTER_RET, msg)
		return
	end


	-- 2. update user info
	user._mailbox_id = mailbox_id

	local scene_server_info = nil
	if user._scene_server_id == 0 then
		scene_server_info = ServiceMgr.get_server_by_scene(scene_id)
	else
		scene_server_info = ServiceMgr.get_server_by_id(user._scene_server_id)
	end

	if not scene_server_info then
		-- TODO fix user scene to a right scene
		Log.err("handle_role_enter: scene server not exists scene_id=%d", scene_id)
		msg.result = ErrorCode.ROLE_ENTER_FAIL
		Net.send_msg(mailbox_id, MID.ROLE_ENTER_RET, msg)
		return
	end
	user._scene_server_id = scene_server_info._server_id
	Log.debug("handle_role_enter: user._scene_server_id=%d", user._scene_server_id)

	-- 3. send msg to scene
	local msg =
	{
		role_id = role_id,
		scene_id = scene_id,	
	}
	scene_server_info:send_msg(MID.ROUTER_ROLE_ENTER_REQ, msg)

end

function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, g_funcs.handle_register_server)

	Net.add_msg_handler(MID.ROLE_ENTER_REQ, handle_role_enter)
end
