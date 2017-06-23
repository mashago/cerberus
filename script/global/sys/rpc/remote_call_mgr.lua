
RemoteCallMgr = {}
RemoteCallMgr._cur_session_id = 0
RemoteCallMgr._all_session_map = {}

function RemoteCallMgr.run(func, ...)
	
	local cor = coroutine.create(func)
	local ret, session_id = coroutine.resume(cor, ...)
	if ret and session_id then
		RemoteCallMgr._all_session_map[session_id] = cor	
	end

	return session_id
end

function RemoteCallMgr.call(mailbox_id, func_name, data)
	-- TODO send msg to mailbox with msg_id is REMOTE_CALL_REQ
	RemoteCallMgr._cur_session_id = RemoteCallMgr._cur_session_id + 1
	return coroutine.yield(RemoteCallMgr._cur_session_id)
end

function RemoteCallMgr.call_nocb(mailbox_id, func_name, data)
	-- just send a msg, no yield
	-- TODO send msg to mailbox with msg_id is REMOTE_CALL_REQ
end

function RemoteCallMgr.callback(session_id, data)

	local cor = RemoteCallMgr._all_session_map[session_id]
	if not cor then
		Log.warn("RemoteCallMgr.callback cor nil session_id=%d", session_id)
		return nil
	end
	RemoteCallMgr._all_session_map[session_id] = nil	

	local ret, session_id = coroutine.resume(cor, data)
	if ret and session_id then
		RemoteCallMgr._all_session_map[session_id] = cor	
	end

	return session_id
end

return RemoteCallMgr
