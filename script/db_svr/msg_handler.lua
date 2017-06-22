

--[[
local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))

	-- send msg to db server

end
--]]

function register_msg_handler()
	-- Net.add_msg_handler(MID.USER_LOGIN_REQ, handle_user_login)
end
