
local ServerMgr = class()

function ServerMgr:ctor()
	--[[
	{[1] = {
		mailbox_id=x,
		server_id=x,
		server_type=x,
		single_scene_list=x,
		from_to_scene_list=x,
		ip=x,
		port=x,
	--]]
	self._register_server_list = {} 

end

-- when other server connect to master server, send REGISTER_SERVER_REQ, will call this function
-- should broadcast new server info to other server, therefore other server will connect to new server. new server will push back into server list
-- if server disconnect, will not remove from server list, just set mailbox_id = 0
function ServerMgr:server_register(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list, ip, port)

	
	local msg = 
	{
		result = ErrorCode.SUCCESS,
		server_id = g_server_conf._server_id,
		server_type = g_server_conf._server_type,
	}

	-- check if exists same server_id
	local is_reconnect = false
	for _, node in ipairs(self._register_server_list) do
		if node.server_id == server_id then
			-- duplicate server_id
			if node.mailbox_id ~= 0 then
				Log.err("ServerMgr:server_register duplicate server_id register %d", server_id)
				msg.result = ErrorCode.REGISTER_SERVER_DUPLICATE
				Net.send_msg(mailbox_id, MID.REGISTER_SERVER_RET, msg)
				return false
			end

			-- server reconnect
			node.mailbox_id = mailbox_id
			is_reconnect = true
		end

		-- send behind server address to reconnect server
		if is_reconnect then
			Net.send_msg(mailbox_id, MID.REGISTER_SERVER_BROADCAST, 
			{
				ip = node.ip,
				port = node.port,
			})
		end

	end

	-- broadcast to before server, let them connect to new server
	local msg = 
	{
		ip = ip,
		port = port,
	}
	for _, node in ipairs(self._register_server_list) do
		Net.send_msg(node.mailbox_id, MID.REGISTER_SERVER_BROADCAST, msg)
	end

	-- push back into server list
	local node = 
	{
		mailbox_id = mailbox_id,
		server_id = server_id, 
		server_type = server_type,
		single_scene_list = single_scene_list,
		from_to_scene_list = from_to_scene_list,
		ip = ip,
		port = port,
	}
	table.insert(self._register_server_list, node)
	
	return true
end

function ServerMgr:server_disconnect(server_id)
	for _, node in ipairs(self._register_server_list) do
		if node.server_id == server_id then
			node.mailbox_id = 0
			break
		end
	end
end

return ServerMgr
