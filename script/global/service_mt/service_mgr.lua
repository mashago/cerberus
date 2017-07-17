
ServiceMgr = {}

function ServiceMgr.get_server_by_id(server_id)
	-- search from ServiceServer first, because is all direct connect inside
	local server_info = ServiceServer.get_server_by_id(server_id)
	if not server_info then
		server_info = ServiceClient.get_server_by_id(server_id)
	end
	return server_info
end

function ServiceMgr.get_server_by_scene(scene_id)
	local server_info = ServiceServer.get_server_by_scene(scene_id)
	if not server_info then
		server_info = ServiceClient.get_server_by_scene(scene_id)
	end
	return server_info
end

function ServiceMgr.get_server_by_type(server_type, opt_key)
	local server_info = ServiceServer.get_server_by_type(server_type, opt_key)
	if not server_info then
		server_info = ServiceClient.get_server_by_type(server_type, opt_key)
	end
	return server_info
end

function ServiceMgr.get_server_by_mailbox(mailbox_id)
	local server_info = ServiceServer.get_server_by_mailbox(mailbox_id)
	if not server_info then
		server_info = ServiceClient.get_server_by_mailbox(mailbox_id)
	end
	return server_info
end


function ServiceMgr.send_by_server_type(server_type, msg_id, data, opt_key)
	local server_info = ServiceServer.get_server_by_type(server_type, opt_key)
	if not server_info then
		server_info = ServiceClient.get_server_by_type(server_type, opt_key)
	end
	if not server_info then
		Log.err("ServiceMgr.send_server_by_type nil %s %d", server_type, opt_key)
		return false
	end

	return server_info:send_msg(msg_id, data)
end


return ServiceMgr
