
-- for c call
function ccall_recv_msg_handler(mailbox_id, msg_id)
	Log.info("ccall_recv_msg_handler: mailbox_id=%d msg_id=%d", mailbox_id, msg_id)
	local msg_name = MID._id_name_map[msg_id] or "unknow msg"
	Log.info("msg_name=%s", msg_name)

	local function error_handler(msg, mailbox_id, msg_id)
		Log.err("error_handler=%s mailbox_id=%d msg_id=%d", msg, mailbox_id, msg_id)
	end
	
	local status = xpcall(g_net_mgr.recv_msg_handler
	, function(msg) return error_handler(msg, mailbox_id, msg_id) end
	, g_net_mgr, mailbox_id, msg_id)

end

function ccall_disconnect_handler(mailbox_id)
	Log.warn("ccall_disconnect_handler mailbox_id=%d", mailbox_id)

	local function error_handler(msg, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_disconnect_handler error : mailbox_id = %d \n%s", mailbox_id, msg)
		return msg 
	end

	local function handle_disconnect(mailbox_id)
		
		local server_info = g_server_mgr:get_server_by_mailbox(mailbox_id)
		if server_info then
			-- server disconnect
			Log.warn("ccall_disconnect_handler server disconnect %d", mailbox_id)
			if g_net_event_server_disconnect and server_info._connect_status == ServiceConnectStatus.CONNECTED then
				g_net_event_server_disconnect(server_info._server_id)
			end
			g_server_mgr:handle_disconnect(mailbox_id)
		else
			-- client disconnect, login and gate handle
			Log.warn("ccall_disconnect_handler client disconnect %d", mailbox_id)
			if g_net_event_client_disconnect then
				g_net_event_client_disconnect(mailbox_id)
			end
		end

		g_net_mgr:del_mailbox(mailbox_id)
	end
	
	local status, msg = xpcall(handle_disconnect
	, function(msg) return error_handler(msg, mailbox_id) end
	, mailbox_id)

	if not status then
		Log.err(msg)
	end
end

function ccall_connect_to_ret_handler(connect_index, mailbox_id)
	Log.info("ccall_connect_to_ret_handler connect_index=%d mailbox_id=%d", connect_index, mailbox_id)

	local function error_handler(msg, connect_index, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_connect_to_ret_handler error : connect_index = %d mailbox_id = %d \n%s", connect_index, mailbox_id, msg)
		return msg 
	end
	
	local status, msg = xpcall(g_server_mgr.connect_to_ret
	, function(msg) return error_handler(msg, connect_index, mailbox_id) end
	, g_server_mgr, connect_index, mailbox_id)

	if not status then
		Log.err(msg)
	end
end

function ccall_connect_to_success_handler(mailbox_id)
	Log.info("ccall_connect_to_success_handler mailbox_id=%d", mailbox_id)

	local function error_handler(msg, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_connect_to_success_handler error : mailbox_id = %d \n%s", mailbox_id, msg)
		return msg 
	end
	
	local status, msg = xpcall(g_server_mgr.connect_to_success
	, function(msg) return error_handler(msg, mailbox_id) end
	, g_server_mgr, mailbox_id)

	if not status then
		Log.err(msg)
	end
end

function ccall_new_connection(mailbox_id, ip, port)
	Log.info("ccall_new_connection mailbox_id=%d ip=%s, port=%d", mailbox_id, ip, port)

	local function error_handler(msg, mailbox_id)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_new_connection error : mailbox_id = %d \n%s", mailbox_id, msg)
		return msg 
	end
	
	local status, msg = xpcall(g_net_mgr.add_mailbox
	, function(msg) return error_handler(msg, mailbox_id) end
	, g_net_mgr, mailbox_id, ip, port)

	if not status then
		Log.err(msg)
	end
end

function ccall_http_response_handler(session_id, response_code, content)

	local function error_handler(msg, session_id, response_code)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_http_response_handler error : session_id = %d response_code = %d \n%s", session_id, response_code, msg)
		return msg 
	end
	
	local status, msg = xpcall(g_http_mgr.handle_request
	, function(msg) return error_handler(msg, session_id, response_code) end
	, g_http_mgr, session_id, response_code, content)

	if not status then
		Log.err(msg)
	end
end

function ccall_timer_handler(timer_index, is_loop)
	-- Log.debug("timer_index=%d", timer_index)
	g_timer:on_timer(timer_index, is_loop)
end

