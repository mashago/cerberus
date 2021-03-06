local net_mgr = require "net.net_mgr"
local timer_mgr = require "timer.timer"
local Log = require "log.logger"
local msg_def = require "global.net_msg_def"
local global_define = require "global.global_define"

local ServiceConnectStatus = global_define.ServiceConnectStatus
local MID = msg_def.MID

-- for c call
function ccall_recv_msg_handler(mailbox_id, msg_id)
	Log.info("ccall_recv_msg_handler: mailbox_id=%d msg_id=%d", mailbox_id, msg_id)
	local msg_name = MID._id_name_map[msg_id] or "unknow msg"
	Log.info("msg_name=%s", msg_name)

	local function error_handler(m, id, mid)
		Log.err("error_handler=%s mailbox_id=%d msg_id=%d", m, id, mid)
	end
	
	xpcall(net_mgr.recv_msg_handler
	, function(msg) return error_handler(msg, mailbox_id, msg_id) end
	, net_mgr, mailbox_id, msg_id)

end

function ccall_connect_ret_handler(session_id, mailbox_id)
	Log.info("ccall_connect_ret_handler session_id=%d mailbox_id=%d", session_id, mailbox_id)

	local function error_handler(msg, s, id)
		msg = debug.traceback(msg, 3)
		msg = string.format("ccall_connect_ret_handler error : session_id=%d mailbox_id = %d \n%s", s, id, msg)
		return msg 
	end

	local rpc_mgr = require "rpc.rpc_mgr"
	local status, msg = xpcall(rpc_mgr.handle_local_callback
	, function(msg) return error_handler(msg, session_id, mailbox_id) end
	, rpc_mgr, session_id, mailbox_id)

	if not status then
		Log.err(msg)
	end
end

function ccall_disconnect_handler(mailbox_id)
	Log.warn("ccall_disconnect_handler mailbox_id=%d", mailbox_id)

	local function error_handler(m, id)
		local msg = debug.traceback(m, 3)
		msg = string.format("ccall_disconnect_handler error : mailbox_id = %d \n%s", id, msg)
		return msg 
	end

	local function handle_disconnect(id)
		local server_mgr = require "server.server_mgr"
		local server_info = server_mgr:get_server_by_mailbox(id)
		if server_info then
			-- server disconnect
			Log.warn("ccall_disconnect_handler server disconnect %d", id)
			if g_net_event_server_disconnect and server_info._connect_status == ServiceConnectStatus.CONNECTED then
				g_net_event_server_disconnect(server_info._server_id)
			end
			net_mgr:dispatch_net_event("server_disconnect", server_info._server_id)
			server_mgr:on_connection_close(server_info)
		else
			-- client disconnect, login and gate handle
			Log.warn("ccall_disconnect_handler client disconnect %d", id)
			if g_net_event_client_disconnect then
				g_net_event_client_disconnect(id)
			end
			net_mgr:dispatch_net_event("client_disconnect", id)
		end

		net_mgr:del_mailbox(id)
	end
	
	local status, msg = xpcall(handle_disconnect
	, function(msg) return error_handler(msg, mailbox_id) end
	, mailbox_id)

	if not status then
		Log.err(msg)
	end
end

function ccall_new_connection(mailbox_id, ip, port)
	Log.info("ccall_new_connection mailbox_id=%d ip=%s, port=%d", mailbox_id, ip, port)

	local function error_handler(msg, id)
		msg = debug.traceback(msg, 3)
		msg = string.format("ccall_new_connection error : mailbox_id = %d \n%s", id, msg)
		return msg 
	end
	
	local status, msg = xpcall(net_mgr.add_mailbox
	, function(msg) return error_handler(msg, mailbox_id) end
	, net_mgr, mailbox_id, ip, port)

	if not status then
		Log.err(msg)
	end
end

function ccall_http_response_handler(session_id, response_code, content)

	local function error_handler(msg, sid, code)
		msg = debug.traceback(msg, 3)
		msg = string.format("ccall_http_response_handler error : session_id = %d response_code = %d \n%s", sid, code, msg)
		return msg 
	end
	
	local http_mgr = require "http.http_mgr"
	local status, msg = xpcall(http_mgr.handle_request
	, function(msg) return error_handler(msg, session_id, response_code) end
	, http_mgr, session_id, response_code, content)

	if not status then
		Log.err(msg)
	end
end

function ccall_timer_handler(timer_index, is_loop)
	-- Log.debug("timer_index=%d", timer_index)
	timer_mgr:on_timer(timer_index, is_loop)
end

function ccall_listen_ret_handler(listen_id, session_id)

	local function error_handler(msg, id, sid)
		msg = debug.traceback(msg, 3)
		msg = string.format("ccall_listen_ret_handler error : listen_id=%d session_id=%d\n%s", id, sid, msg)
		return msg 
	end
	
	local rpc_mgr = require "rpc.rpc_mgr"
	local status, msg = xpcall(rpc_mgr.handle_local_callback
	, function(msg) return error_handler(msg, listen_id, session_id) end
	, rpc_mgr, session_id, listen_id)

	if not status then
		Log.err(msg)
	end
end

-- default do nothing
function ccall_stdin_handler(buffer)
	Log.info("ccall_stdin_handler buffer=%s", buffer)
end
