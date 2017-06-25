
local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))

	local func = function(mailbox_id, username, password)
		local db_server_id = ServiceClient.get_server_id_by_type(ServerType.DB)
		if not db_server_id then
			Log.err("handle_user_login no db server")
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.CREATE_ROLE_FAIL)
			return
		end

		local status, result = RpcMgr.call(db_server_id, "db_user_login", {username=username, password=password})
		if not status then
			Log.err("handle_user_login rpc call fail")
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, ErrorCode.CREATE_ROLE_FAIL)
			return
		end

		Log.debug("handle_user_login: callback result=%s", Util.TableToString(result))

		-- TODO check mailbox_id is still legal, after rpc
		Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, result.result)
	end
	RpcMgr.run(func, mailbox_id, data.username, data.password)

end

local function handle_register_server(data, mailbox_id, msg_id)
	Log.debug("handle_register_server: data=%s", Util.TableToString(data))

	-- check mailbox is trust
	-- add into server list
	-- send other server list to server
	-- broadcast to other server
	
	local mailbox = Net.get_mailbox(mailbox_id)
	if not mailbox then
		Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, ServerErrorCode.REGISTER_FAIL, 0, 0)
		return
	end

	if mailbox.conn_type ~= ConnType.TRUST then
		Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, ServerErrorCode.REGISTER_UNTRUST, 0, 0)
		return
	end

	-- add server
	ServiceServer.add_server(mailbox_id, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)

	Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, ServerErrorCode.SUCCESS, ServerConfig._server_id, ServerConfig._server_type)

	-- broadcast
	for server_id, server_info in pairs(ServiceServer._all_server_map) do
		if server_id ~= data.server_id then
			Net.send_msg(server_info._mailbox_id, MID.REGISTER_SERVER_BROADCAST, data.server_id, data.server_type, data.single_scene_list, data.from_to_scene_list)
			Net.send_msg(mailbox_id, MID.REGISTER_SERVER_BROADCAST, server_info._server_id, server_info._server_type, server_info._single_scene_list, server_info._from_to_scene_list)
		end
	end

end

function register_msg_handler()
	Net.add_msg_handler(MID.USER_LOGIN_REQ, handle_user_login)
	Net.add_msg_handler(MID.REGISTER_SERVER_REQ, handle_register_server)
end
