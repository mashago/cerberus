
local Log = require "log.logger"
local Env = require "env"
function g_net_event_server_disconnect(server_id)
	Env.area_mgr:remove_by_server_id(server_id)
end

function g_net_event_client_disconnect(mailbox_id)
	-- get user by mailbox_id
	local user = Env.user_mgr:get_user_by_mailbox(mailbox_id)
	if not user then
		return
	end

	Log.info("g_net_event_client_disconnect: user_id=%d", user._user_id)
	Env.user_mgr:del_user(user)
end

function g_net_event_client_msg(msg_handler, data, mailbox_id, msg_id)

	local user = Env.user_mgr:get_user_by_mailbox(mailbox_id)
	if not user then
		Log.warn("g_net_event_client_msg: user nil msg_id=%d", msg_id)
		return
	end

	msg_handler(user, data, mailbox_id, msg_id)
end
