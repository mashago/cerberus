
Services = {}

Services._all_server_list = {}
Services._connect_server_map = {}

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

function Services.create_connect_timer(ms)

	local function timer_cb(arg)
		Log.debug("Service timer_cb")
		-- Log.debug("handle_client_test: Services._all_server_list=%s", tableToString(Services._all_server_list))
		
		local is_all_connected = true
		for _, server_info in ipairs(Services._all_server_list) do
			if not server_info._is_connected then
				is_all_connected = false
			end
			Log.debug("ip=%s port=%d", server_info._ip, server_info._port)
			if not server_info._is_connecting then
				local ret, mailbox_id = g_network:connect_to(server_info._ip, server_info._port)
				if ret then
					server_info._mailbox_id = mailbox_id
					server_info._is_connecting = true
				end

			end
		end
		if is_all_connected then
			Timer.del_timer(Services._connect_timer_index)
		end
	end

	Services._connect_timer_index = Timer.add_timer(ms, timer_cb, 0, true)
end

function Services.connect_to_success(mailbox_id)
	for _, server_info in ipairs(Services._all_server_list) do
		if server_info._mailbox_id == mailbox_id then
			server_info._is_connecting = false
			server_info._is_connected = true
			break
		end
	end
end

return Services
