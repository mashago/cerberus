
function g_net_event_server_connect(server_id)

	local server_info = g_service_mgr:get_server_by_id(server_id)
	if server_info._server_type == ServerType.LOGIN then
		-- register area
		local msg = 
		{
			area_list = g_server_conf._area_list,
		}

		server_info:send_msg(MID.REGISTER_AREA_REQ, msg)
	end
end

