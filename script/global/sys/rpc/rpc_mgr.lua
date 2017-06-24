
RpcMgr = {}
RpcMgr._cur_session_id = 0
RpcMgr._all_session_map = {}
RpcMgr._all_call_func = {}

function RpcMgr.run(func, ...)
	
	local cor = coroutine.create(func)
	local ret, session_id = coroutine.resume(cor, ...)
	if ret and session_id then
		RpcMgr._all_session_map[session_id] = cor	
	end

	return session_id
end

function RpcMgr.call(server_id, func_name, data)
	local data_str = Util.serialize(data)
	RpcMgr._cur_session_id = RpcMgr._cur_session_id + 1
	if not ServiceClient.send_msg(server_id, MID.REMOTE_CALL_REQ, RpcMgr._cur_session_id, func_name, Util.serialize(data)) then
		return false
	end
	return coroutine.yield(RpcMgr._cur_session_id)
end

function RpcMgr.call_nocb(server_id, func_name, data)
	-- just send a msg, no yield
	-- TODO send msg to mailbox with msg_id is REMOTE_CALL_REQ
end

function RpcMgr.callback(session_id, result, data)

	local cor = RpcMgr._all_session_map[session_id]
	if not cor then
		Log.warn("RpcMgr.callback cor nil session_id=%d", session_id)
		return nil
	end
	RpcMgr._all_session_map[session_id] = nil	

	local ret, session_id = coroutine.resume(cor, result, data)
	if ret and session_id then
		RpcMgr._all_session_map[session_id] = cor	
	end

	return session_id
end

function RpcMgr.register_call_func(func_name, func)
	if not RpcMgr._all_call_func[func_name] then
		Log.err("RpcMgr.register_call_func func_name duplicate %s", func_name)
		return
	end
	RpcMgr._all_call_func[func_name] = func
end

function RpcMgr.handle_call(data, mailbox_id, msg_id)
	local session_id = data.session_id
	local func_name = data.func_name
	local param = Util.unserialize(data.param)
	local func = RpcMgr._all_call_func[func_name]
	if not func then
		-- TODO send back
		Log.err("RpcMgr.handle_call func not exists %s", func_name)
		Net.send_msg(mailbox_id, MID.REMOTE_CALL_RET, false, session_id, "")
		return
	end
	
	-- TODO consider rpc inside
	local ret = func(param)
	Net.send_msg(mailbox_id, MID.REMOTE_CALL_RET, true, session_id, Util.serialize(data))

end

function RpcMgr.handle_callback(data, mailbox_id, msg_id)
	local result = data.result
	local session_id = data.session_id
	local param = Util.unserialize(data.param)

	RpcMgr.callback(session_id, result, {result=1, user_id=1001})

end

Net.add_msg_handler(MID.REMOTE_CALL_REQ, RpcMgr.handle_call)
Net.add_msg_handler(MID.REMOTE_CALL_RET, RpcMgr.handle_callback)

return RpcMgr
