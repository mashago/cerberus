
local g_area_mgr = g_area_mgr
local Log = require "core.log.logger"
function g_net_event_server_disconnect(server_id)
	g_area_mgr:remove_by_server_id(server_id)
end

function g_net_event_client_disconnect(mailbox_id)
	local g_user_mgr = g_user_mgr
	-- get user by mailbox_id
	local user = g_user_mgr:get_user_by_mailbox(mailbox_id)
	if not user then
		return
	end

	Log.info("g_net_event_client_disconnect: user_id=%d", user._user_id)
	g_user_mgr:del_user(user)
end

function g_net_event_client_msg(msg_handler, data, mailbox_id, msg_id)
	local g_user_mgr = g_user_mgr

	local user = g_user_mgr:get_user_by_mailbox(mailbox_id)
	if not user then
		Log.warn("g_net_event_client_msg: user nil msg_id=%d", msg_id)
		return
	end

	msg_handler(user, data, mailbox_id, msg_id)
end
