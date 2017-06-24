
local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))

	local func = function(mailbox_id, username, password)
		local db_server_id = ServiceClient.get_server_id_by_type(ServerType.DB)
		if not db_server_id then
			Log.err("handle_user_login no db server")
			return
		end

		local result, ret = RpcMgr.call(db_server_id, "user_login", {username=username, password=password})
		if not result then
			Log.err("handle_user_login rpc call fail")
			Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, 0)
			return
		end

		Log.debug("handle_user_login: callback ret=%s", Util.TableToString(ret))
		-- TODO check mailbox_id is still legal, after rpc
		Net.send_msg(mailbox_id, MID.USER_LOGIN_RET, 1)
	end
	RpcMgr.run(func, mailbox_id, data.username, data.password)

	-- for test
	-- local session_id = RpcMgr.run(func)
	-- fake callback from db server
	-- RpcMgr.callback(session_id, {result=1, user_id=1001})

end

function register_msg_handler()
	Net.add_msg_handler(MID.USER_LOGIN_REQ, handle_user_login)
end
