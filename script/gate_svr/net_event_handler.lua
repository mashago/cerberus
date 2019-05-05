
local server_mgr = require "server.server_mgr"
local Log = require "log.logger"
local Env = require "env"
local global_define = require "global.global_define"
local ServerType = global_define.ServerType

function g_net_event_server_connect(server_id)
	local server_info = server_mgr:get_server_by_id(server_id)
	if server_info._server_type == ServerType.BRIDGE then
		Env.common_handler:add_sync_conn_num_timer()
	end
end

function g_net_event_server_disconnect(server_id)
	local server_info = server_mgr:get_server_by_id(server_id)
	if server_info._server_type == ServerType.BRIDGE then
		Env.common_handler:del_sync_conn_num_timer()
	end
end

function g_net_event_client_disconnect(mailbox_id)
	-- get user by mailbox_id
	local user = Env.user_mgr:get_user_by_mailbox(mailbox_id)
	if not user then
		return
	end

	Log.info("g_net_event_client_disconnect: user_id=%d", user._user_id)
	return Env.user_mgr:user_offline(user)
end

