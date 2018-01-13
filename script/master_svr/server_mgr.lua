
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

-- when other server connect to master server, send SHAKE_HAND_REQ, will call this function
-- will invite new server connect to forward other server, so send other server addr to new server. and new server will push back into server list
-- if server disconnect, will not remove from server list, just set mailbox_id = 0
function ServerMgr:shake_hand(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list, ip, port)

	
	local msg = 
	{
		result = ErrorCode.SUCCESS,
		server_id = g_server_conf._server_id,
		server_type = g_server_conf._server_type,
		single_scene_list = g_server_conf._single_scene_list,
		from_to_scene_list = g_server_conf._from_to_scene_list,
	}

	-- add server
	local new_server_info = g_service_mgr:add_server(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list)
	if not new_server_info then
		msg.result = ErrorCode.SHAKE_HAND_FAIL
		Net.send_msg(mailbox_id, MID.SHAKE_HAND_RET, msg)
		return false
	end

	-- check if exists same server_id
	local reconn_server_index = 0
	local server_list = {}
	for index, node in ipairs(self._register_server_list) do
		if node.server_id ~= server_id then
			table.insert(server_list, 
			{
				ip = node.ip,
				port = node.port,
			})
			goto continue
		end

		-- duplicate server_id
		if node.mailbox_id ~= 0 then
			Log.err("ServerMgr:shake_hand duplicate server_id register %d", server_id)
			msg.result = ErrorCode.SHAKE_HAND_FAIL
			Net.send_msg(mailbox_id, MID.SHAKE_HAND_RET, msg)
			return false
		end

		-- server reconnect
		node.mailbox_id = mailbox_id
		reconn_server_index = index
		break

		::continue::
	end

	Net.send_msg(mailbox_id, MID.SHAKE_HAND_RET, msg)

	-- shake hand server is reconnect server
	if reconn_server_index > 0 then
		-- send before server_list to reconnect server
		local msg =
		{
			server_list = server_list
		}
		Net.send_msg(mailbox_id, MID.SHAKE_HAND_INVITE, msg)

		-- send reconnect server addr to behind server

		local msg = 
		{
			server_list =
			{
				{
					ip = ip,
					port = port,
				}
			}
		}
		for i=reconn_server_index+1, #self._register_server_list do
			local node = self._register_server_list[i]
			if node.mailbox_id > 0 then
				Net.send_msg(node.mailbox_id, MID.SHAKE_HAND_INVITE, msg)
			end
		end
		self:print()
		return true
	end

	-- shake hand server is new server
	-- invite new server to connect them
	if #self._register_server_list > 0 then
		local msg = 
		{
			server_list = {}
		}
		for _, node in ipairs(self._register_server_list) do
			table.insert(msg.server_list, 
			{
				ip = node.ip,
				port = node.port,
			})
		end
		Net.send_msg(mailbox_id, MID.SHAKE_HAND_INVITE, msg)
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
	
	self:print()
	return true
end

function ServerMgr:server_disconnect(server_id)
	for _, node in ipairs(self._register_server_list) do
		if node.server_id == server_id then
			node.mailbox_id = 0
			break
		end
	end
	self:print()
end

function ServerMgr:print()
	Log.info("\n####### ServerMgr:print #######")
	for k, v in ipairs(self._register_server_list) do
		Log.info("[%d] mailbox_id=%d server_id=%d server_type=%d single_scene_list=[%s] from_to_scene_list=[%s] ip=%s port=%d"
		, k, v.mailbox_id, v.server_id, v.server_type, table.concat(v.single_scene_list, ","), table.concat(v.from_to_scene_list, ","), v.ip, v.port)
	end
	Log.info("#######\n")
end

return ServerMgr
