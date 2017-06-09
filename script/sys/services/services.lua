
Services = {}

Services._all_connect_servers = {}
Services._connect_server_session_id_map = {}

function Services.add_connect_service(ip, port, desc)
	local server_info = 
	{
		_server_id = 0, 
		_server_type = 0, 
		_ip = ip, 
		_port = port, 
		_desc = desc, 
		_session_id = -1,
		_is_registed = false,
		_is_connecting = false,
		_is_connected = false,
		_last_connect_time = 0,
	}
	table.insert(Services._all_connect_servers, server_info)
end

function Services.create_connect_timer(ms)

	local function timer_cb(arg)
		Log.debug("Service timer_cb")
		-- Log.debug("handle_client_test: Services._all_connect_servers=%s", tableToString(Services._all_connect_servers))
		
		local is_all_connected = true
		for _, server_info in pairs(Services._all_connect_servers) do
			if not server_info._is_connected then
				is_all_connected = false
			end
			Log.debug("ip=%s port=%d", server_info._ip, server_info._port)
			if not server_info._is_connecting then
				local ret, session_id = g_network:connect_to(server_info._ip, server_info._port)
				if ret then
					server_info._session_id = session_id
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

return Services
