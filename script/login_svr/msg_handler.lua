
local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))

	-- send msg to db server
	
	local func = function(mailbox_id, username, password)

		-- send data to db server
		
		local db_mailbox_id = 1
		local ret = RemoteCallMgr.call(db_mailbox_id, "user_login", {username=username, password=password})
		Log.debug("handle_user_login: callback ret=%s", Util.TableToString(ret))

	end
	-- RemoteCallMgr.run(func)

	-- for test
	local session_id = RemoteCallMgr.run(func)
	-- fake callback from db server
	RemoteCallMgr.callback(session_id, {result=1, user_id=1001})

end

function register_msg_handler()
	Net.add_msg_handler(MID.USER_LOGIN_REQ, handle_user_login)
end
