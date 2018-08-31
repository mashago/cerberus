
local Core = require "core"
local Log = require "core.log.logger"
local ServerType = ServerType
local Env = require "env"

function g_net_event_server_connect(server_id)
	local server_info = Core.server_mgr:get_server_by_id(server_id)
	if server_info._server_type == ServerType.BRIDGE then
		Env.g_common_handler:add_sync_conn_num_timer()
	end
end

function g_net_event_server_disconnect(server_id)
	local server_info = Core.server_mgr:get_server_by_id(server_id)
	if server_info._server_type == ServerType.BRIDGE then
		Env.g_common_handler:del_sync_conn_num_timer()
	end
end

function g_net_event_client_disconnect(mailbox_id)
	-- get user by mailbox_id
	local user = Env.g_user_mgr:get_user_by_mailbox(mailbox_id)
	if not user then
		return
	end

	Log.info("g_net_event_client_disconnect: user_id=%d", user._user_id)
	return Env.g_user_mgr:user_offline(user)
end

