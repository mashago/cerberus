
local PeerMgr = class()

function PeerMgr:ctor()
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
	self._register_peer_list = {} 

end

-- when other server connect to master server, send s2s_shake_hand_req, will call this function
-- will invite new server connect to forward other server, so send other server addr to new server. and new server will push back into server list
-- if server disconnect, will not remove from server list, just set mailbox_id = 0
function PeerMgr:shake_hand(mailbox_id, server_id, server_type, single_scene_list, from_to_scene_list, ip, port)

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
		g_net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_ret, msg)
		return false
	end

	-- check if exists same server_id
	local reconn_peer_index = 0
	local peer_list = {}
	for index, peer in ipairs(self._register_peer_list) do
		if peer.server_id ~= server_id then
			table.insert(peer_list, 
			{
				ip = peer.ip,
				port = peer.port,
			})
			goto continue
		end

		-- duplicate server_id
		if peer.mailbox_id ~= 0 then
			Log.err("PeerMgr:shake_hand duplicate server_id register %d", server_id)
			msg.result = ErrorCode.SHAKE_HAND_FAIL
			g_net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_ret, msg)
			return false
		end

		-- server reconnect
		peer.mailbox_id = mailbox_id
		reconn_peer_index = index
		break

		::continue::
	end

	g_net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_ret, msg)

	-- shake hand server is reconnect server
	if reconn_peer_index > 0 then
		-- send before peer_list to reconnect server
		local msg =
		{
			peer_list = peer_list
		}
		g_net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_invite, msg)

		-- send reconnect server addr to behind server

		local msg = 
		{
			peer_list =
			{
				{
					ip = ip,
					port = port,
				}
			}
		}
		for i=reconn_peer_index+1, #self._register_peer_list do
			local peer = self._register_peer_list[i]
			if peer.mailbox_id > 0 then
				g_net_mgr:send_msg(peer.mailbox_id, MID.s2s_shake_hand_invite, msg)
			end
		end
		self:print()
		return true
	end

	-- shake hand peer is new peer
	-- invite new peer to connect them
	if #self._register_peer_list > 0 then
		local msg = 
		{
			peer_list = {}
		}
		for _, peer in ipairs(self._register_peer_list) do
			table.insert(msg.peer_list, 
			{
				ip = peer.ip,
				port = peer.port,
			})
		end
		g_net_mgr:send_msg(mailbox_id, MID.s2s_shake_hand_invite, msg)
	end

	-- push back into peer list
	local peer = 
	{
		mailbox_id = mailbox_id,
		server_id = server_id, 
		server_type = server_type,
		single_scene_list = single_scene_list,
		from_to_scene_list = from_to_scene_list,
		ip = ip,
		port = port,
	}
	table.insert(self._register_peer_list, peer)
	
	self:print()
	return true
end

function PeerMgr:server_disconnect(server_id)
	local target_peer
	for _, peer in ipairs(self._register_peer_list) do
		if peer.server_id == server_id then
			peer.mailbox_id = 0
			target_peer = peer
			break
		end
	end
	if not target_peer then
		return
	end

	for index, peer in ipairs(self._register_peer_list) do
		if peer.mailbox_id ~= 0 then
			g_net_mgr:send_msg(peer.mailbox_id, MID.s2s_shake_hand_cancel, target_peer)
		end
	end

	self:print()
end

function PeerMgr:print()
	Log.info("\n####### PeerMgr:print #######")
	for k, v in ipairs(self._register_peer_list) do
		Log.info("[%d] mailbox_id=%d server_id=%d server_type=%d single_scene_list=[%s] from_to_scene_list=[%s] ip=%s port=%d"
		, k, v.mailbox_id, v.server_id, v.server_type, table.concat(v.single_scene_list, ","), table.concat(v.from_to_scene_list, ","), v.ip, v.port)
	end
	Log.info("#######\n")
end

return PeerMgr
