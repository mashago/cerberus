
Services = {}

Services._all_server_list = {} -- {server_info1, server_info2, ...}
Services._connect_server_map = {} -- {mailbox_id1 = server_info1, ...}
Services._is_connect_timer_running = false
Services._connect_interval_ms = 2000

function Services.is_service(mailbox_id)
	for _, server_info in ipairs(Services._all_server_list) do
		if server_info._mailbox_id == mailbox_id then
			return true
		end
	end
	return false
end

function Services.add_connect_service(ip, port, desc)
	local server_info = 
	{
		_server_id = 0, 
		_server_type = 0, 
		_ip = ip, 
		_port = port, 
		_desc = desc, 
		_mailbox_id = -1,
		_is_registed = false,
		_is_connecting = false,
		_is_connected = false,
		_last_connect_time = 0,
	}
	table.insert(Services._all_server_list, server_info)
end

function Services.create_connect_timer()

	local function timer_cb(arg)
		Log.debug("Service timer_cb")
		-- Log.debug("handle_client_test: Services._all_server_list=%s", tableToString(Services._all_server_list))
		local now_time = os.time()
		
		local is_all_connected = true
		for _, server_info in ipairs(Services._all_server_list) do
			if not server_info._is_connected then
				is_all_connected = false
				if not server_info._is_connecting then
					Log.debug("connect to ip=%s port=%d", server_info._ip, server_info._port)
					local ret, mailbox_id = g_network:connect_to(server_info._ip, server_info._port)
					-- Log.debug("ret=%s mailbox_id=%d", ret and "true" or "false", mailbox_id)
					if ret then
						server_info._mailbox_id = mailbox_id
						server_info._is_connecting = true
						server_info._last_connect_time = now_time
					else
						Log.warn("******* connect to fail ip=%s port=%d", server_info._ip, server_info._port)
					end
				else
					Log.debug("connecting mailbox_id=%d ip=%s port=%d", server_info._mailbox_id, server_info._ip, server_info._port)
					if now_time - server_info._last_connect_time > 5 then
						-- connect time too long, close this connect
						Log.warn("!!!!!!! connecting timeout mailbox_id=%d ip=%s port=%d", server_info._mailbox_id, server_info._ip, server_info._port)
						g_network:close_mailbox(server_info._mailbox_id) -- will cause luaworld:HandleDisconnect
						server_info._mailbox_id = -1
						server_info._is_connecting = false
					end
				end
			end
		end
		if is_all_connected then
			Log.debug("******* all connect *******")
			Timer.del_timer(Services._connect_timer_index)
			Services._is_connect_timer_running = false
		end
	end

	Services._is_connect_timer_running = true
	Services._connect_timer_index = Timer.add_timer(Services._connect_interval_ms, timer_cb, 0, true)
end

function Services.disconnect(mailbox_id)
	Log.info("Services.disconnect mailbox_id=%d", mailbox_id)

	for _, server_info in ipairs(Services._all_server_list) do
		if server_info._mailbox_id == mailbox_id then
			-- set disconnect
			server_info._mailbox_id = -1
			server_info._is_connecting = false
			server_info._is_connected = false
			break
		end
	end

	Services._connect_server_map[mailbox_id] = nil

	if Services._is_connect_timer_running then
		-- do nothing, connect timer will do reconnect
		-- Log.debug("connect timer is running")
		return
	end

	-- connect timer already close, start it
	Services.create_connect_timer()

end

function Services.connect_to_success(mailbox_id)
	for _, server_info in ipairs(Services._all_server_list) do
		if server_info._mailbox_id == mailbox_id then
			server_info._is_connecting = false
			server_info._is_connected = true

			-- send register msg

			Net.send_msg(mailbox_id, MID.REGISTER_SERVER_REQ, 1, 1)

			break
		end
	end
end

return Services
