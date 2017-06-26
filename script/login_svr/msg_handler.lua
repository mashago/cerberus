
local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))

	local func = function(mailbox_id, username, password)
		local server = ServiceClient.get_server_by_type(ServerType.DB)
		if not server then
			Log.err("handle_user_login no db server")
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.USER_LOGIN_FAIL)
			return
		end

		local status, result = RpcMgr.call(server, "db_user_login", {username=username, password=password})
		if not status then
			Log.err("handle_user_login rpc call fail")
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.USER_LOGIN_FAIL)
			return
		end

		Log.debug("handle_user_login: callback result=%s", Util.TableToString(result))

		-- TODO check client mailbox_id is still legal, after rpc
		Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, result.result)
	end
	RpcMgr.run(func, mailbox_id, data.username, data.password)

end

local function handle_create_role(data, mailbox_id, msg_id)
	Log.debug("handle_create_role: data=%s", Util.TableToString(data))

	local func = function(mailbox_id, role_name)

		local channel_id = 400001 -- TODO read from client
		local role_id = math.random(10000)

		local server = ServiceServer.get_server_by_scene(channel_id)
		if not server then
			Log.err("handle_create_role no bridge server")
			Net.send_msg(mailbox_id, MID.CREATE_ROLE_RET, ErrorCode.CREATE_ROLE_FAIL)
			return
		end

		local status, result = RpcMgr.call(server, "bridge_create_role", {role_id=role_id, role_name=role_name})
		if not status then
			Log.err("handle_create_role rpc call fail")
			Net.send_msg(mailbox_id, MID.CREATE_ROLE_RET, ErrorCode.CREATE_ROLE_FAIL)
			return
		end

		Log.debug("handle_create_role: callback result=%s", Util.TableToString(result))

		-- TODO check mailbox_id is still legal, after rpc
		Net.send_msg(mailbox_id, MID.CREATE_ROLE_RET, result.result, result.role_id or 0)
	end
	RpcMgr.run(func, mailbox_id, data.role_name)

end

function register_msg_handler()
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, g_handle_register_server)

	Net.add_msg_handler(MID.USER_LOGIN_REQ, handle_user_login)
	Net.add_msg_handler(MID.CREATE_ROLE_REQ, handle_create_role)
end
