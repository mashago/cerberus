
RpcMgr = {}
RpcMgr._cur_session_id = 0
RpcMgr._all_session_map = {} -- {[session_id] = coroutine}
RpcMgr._all_call_func = {} -- { function(data){return {}} }
RpcMgr._original_session_map = {} -- {[new_session_id] = {session_id=x, mailbox_id=y}}

-- rpc warpper
function RpcMgr.run(func, ...)
	local cor = coroutine.create(func)
	local status, session_id = coroutine.resume(cor, ...)
	if status and session_id then
		-- return session_id if has rpc inside
		RpcMgr._all_session_map[session_id] = cor	
	end
end

-- rpc call function
function RpcMgr.call(server, func_name, data)
	local data_str = Util.serialize(data)
	RpcMgr._cur_session_id = RpcMgr._cur_session_id + 1
	if not Net.send_msg(server.mailbox_id, MID.REMOTE_CALL_REQ, RpcMgr._cur_session_id, func_name, Util.serialize(data)) then
		return false
	end
	return coroutine.yield(RpcMgr._cur_session_id)
end

function RpcMgr.callback(session_id, result, data)

	local cor = RpcMgr._all_session_map[session_id]
	if not cor then
		Log.warn("RpcMgr.callback cor nil session_id=%d", session_id)
		return
	end
	RpcMgr._all_session_map[session_id] = nil	

	local status, result = coroutine.resume(cor, result, data)
	if not status then
		Log.err("RpcMgr.callback cor resume fail")
		return
	end

	if type(result) == "number" then
		-- another rpc inside
		local new_session_id = result
		RpcMgr._all_session_map[new_session_id] = cor	
		return
	end

	-- rpc finish
	-- check if this func is a rpc from otherwhere
	local origin = RpcMgr._original_session_map[session_id]
	if not origin then
		return
	end

	RpcMgr._original_session_map[session_id] = nil
	Net.send_msg(origin.mailbox_id, MID.REMOTE_CALL_RET, true, origin.session_id, Util.serialize(result))

end

function RpcMgr.handle_call(data, mailbox_id, msg_id)
	local session_id = data.session_id
	local func_name = data.func_name
	local param = Util.unserialize(data.param)
	local func = RpcMgr._all_call_func[func_name]
	if not func then
		Log.err("RpcMgr.handle_call func not exists %s", func_name)
		Net.send_msg(mailbox_id, MID.REMOTE_CALL_RET, false, session_id, "")
		return
	end
	
	-- local ret = func(param)
	-- Net.send_msg(mailbox_id, MID.REMOTE_CALL_RET, true, session_id, Util.serialize(ret))

	-- consider rpc in call function
	-- so use a coroutine wrap this function
	local cor = coroutine.create(func)
	local status, result = coroutine.resume(cor, param)
	if not status or not result then
		Log.err("RpcMgr.handle_call resume error func_name=%s", func_name)
		Net.send_msg(mailbox_id, MID.REMOTE_CALL_RET, false, session_id, "")
		return
	end

	if type(result) == "number" then
		-- has rpc inside, result is a session_id
		-- mark down this coroutine and session_id
		local new_session_id = result
		RpcMgr._all_session_map[new_session_id] = cor	

		-- mark down the way back to caller
		local origin = {}
		origin.session_id = session_id
		origin.mailbox_id = mailbox_id
		RpcMgr._original_session_map[new_session_id] = origin

	else
		-- result is a table, no rpc inside, just send back result
		Net.send_msg(mailbox_id, MID.REMOTE_CALL_RET, true, session_id, Util.serialize(result))
	end
end

function RpcMgr.handle_callback(data, mailbox_id, msg_id)
	local result = data.result
	local session_id = data.session_id
	local param = Util.unserialize(data.param)

	RpcMgr.callback(session_id, result, param)

end

Net.add_msg_handler(MID.REMOTE_CALL_REQ, RpcMgr.handle_call)
Net.add_msg_handler(MID.REMOTE_CALL_RET, RpcMgr.handle_callback)

return RpcMgr
