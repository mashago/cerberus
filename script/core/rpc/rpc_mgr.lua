
RpcMgr = {}
RpcMgr._cur_session_id = 0
RpcMgr._all_session_map = {} -- {[session_id] = coroutine}
RpcMgr._all_call_func = {} -- { func_name = function(data){return {}} }
RpcMgr._origin_map = {} -- { [new_session_id] = {from_server_id=x, to_server_id=y, session_id=z} }

-- rpc warpper
function RpcMgr.run(func, ...)
	local cor = coroutine.create(func)
	local status, result = coroutine.resume(cor, ...)
	if not status then
		Log.err("RpcMgr.run: resume error %s", result)
		return
	end
	if not result then
		-- no rpc inside, do nothing
		return
	end

	if type(result) ~= "number" then
		Log.err("RpcMgr.run: run result not a session_id")
		return
	end

	local session_id = result
	-- return session_id if has rpc inside
	RpcMgr._all_session_map[session_id] = cor	
end

-- rpc call function
function RpcMgr.call(server_info, func_name, data)
	local data_str = Util.serialize(data)
	RpcMgr._cur_session_id = RpcMgr._cur_session_id + 1
	local msg = 
	{
		from_server_id = g_server_conf._server_id, 
		to_server_id = server_info._server_id, 
		session_id = RpcMgr._cur_session_id, 
		func_name = func_name, 
		param = Util.serialize(data),
	}
	if not server_info:send_msg(MID.REMOTE_CALL_REQ, msg) then
		return false
	end
	return coroutine.yield(RpcMgr._cur_session_id)
end

function RpcMgr.call_by_server_type(server_type, func_name, data, opt_key)
	local server_info = ServiceMgr.get_server_by_type(server_type, opt_key)
	if not server_info then return false end
	return RpcMgr.call(server_info, func_name, data)
end

function RpcMgr.call_by_server_id(server_id, func_name, data)
	local server_info = ServiceMgr.get_server_by_id(server_id)
	if not server_info then return false end
	return RpcMgr.call(server_info, func_name, data)
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
		Log.err("RpcMgr.callback: cor resume error %s", result)
		return
	end

	if type(result) == "number" then
		-- another rpc inside
		local new_session_id = result
		RpcMgr._all_session_map[new_session_id] = cor	
		-- if has origin data, fix to new session id
		local origin = RpcMgr._origin_map[session_id]
		if origin then
			RpcMgr._origin_map[session_id] = nil
			RpcMgr._origin_map[new_session_id] = origin
		end
		return
	end

	-- rpc finish
	-- check if this func is a rpc from otherwhere
	local origin = RpcMgr._origin_map[session_id]
	if not origin then
		return
	end
	RpcMgr._origin_map[session_id] = nil

	local server_info = ServiceMgr.get_server_by_id(origin.from_server_id)
	if not server_info then
		Log.warn("RpcMgr.callback cannot go back from_server_id=%d", origin.from_server_id)
		return
	end

	local msg =
	{
		result = true, 
		from_server_id = origin.from_server_id, 
		to_server_id = origin.to_server_id, 
		session_id = origin.session_id, 
		param = Util.serialize(result)
	}
	server_info:send_msg(MID.REMOTE_CALL_RET, msg)

end

function RpcMgr.handle_call(data, mailbox_id, msg_id)
	local from_server_id = data.from_server_id
	local to_server_id = data.to_server_id
	local session_id = data.session_id
	local func_name = data.func_name

	-- transfer rpc req to to server
	if to_server_id ~= g_server_conf._server_id then
		local server_info = ServiceMgr.get_server_by_id(to_server_id)
		if not server_info then
			Log.warn("RpcMgr.handle_call cannot go to to_server_id=%d", to_server_id)
			local msg =
			{
				result = false, 
				from_server_id = from_server_id, 
				to_server_id = to_server_id, 
				session_id = session_id, 
				param = ""
			}
			Net.send_msg(mailbox_id, MID.REMOTE_CALL_RET, msg)
			return
		end

		server_info:send_msg(MID.REMOTE_CALL_REQ, data)
		return
	end

	local param = Util.unserialize(data.param)
	local func = RpcMgr._all_call_func[func_name]
	if not func then
		Log.err("RpcMgr.handle_call func not exists %s", func_name)
		local msg =
		{
			result = false, 
			from_server_id = from_server_id, 
			to_server_id = to_server_id, 
			session_id = session_id, 
			param = ""
		}
		Net.send_msg(mailbox_id, MID.REMOTE_CALL_RET, msg)
		return
	end

	-- handle rpc
	-- consider rpc in call function
	-- so use a coroutine wrap this function
	local cor = coroutine.create(func)
	local status, result = coroutine.resume(cor, param)
	if not status or not result then
		Log.err("RpcMgr.handle_call resume error func_name=%s %s", func_name, result)
		local msg =
		{
			result = false, 
			from_server_id = from_server_id, 
			to_server_id = to_server_id, 
			session_id = session_id, 
			param = ""
		}
		Net.send_msg(mailbox_id, MID.REMOTE_CALL_RET, msg)
		return
	end

	if type(result) == "number" then
		-- has rpc inside, result is a session_id
		-- mark down this coroutine and session_id
		local new_session_id = result
		RpcMgr._all_session_map[new_session_id] = cor	

		-- mark down the way back to caller
		local origin = {}
		origin.from_server_id = from_server_id
		origin.to_server_id = to_server_id
		origin.session_id = session_id
		RpcMgr._origin_map[new_session_id] = origin

	else
		-- result is a table, no rpc inside, just send back result
		local msg =
		{
			result = true, 
			from_server_id = from_server_id, 
			to_server_id = to_server_id, 
			session_id = session_id, 
			param = Util.serialize(result)
		}
		Net.send_msg(mailbox_id, MID.REMOTE_CALL_RET, msg)
	end
end

function RpcMgr.handle_callback(data, mailbox_id, msg_id)
	local result = data.result
	local session_id = data.session_id
	local from_server_id = data.from_server_id
	local to_server_id = data.to_server_id

	-- transfer rpc ret to from server
	if from_server_id ~= g_server_conf._server_id then
		local server_info = ServiceMgr.get_server_by_id(from_server_id)
		if not server_info then
			Log.warn("RpcMgr.handle_callback cannot go back from_server_id=%d", from_server_id)
			return
		end

		local msg =
		{
			result = true, 
			from_server_id = from_server_id, 
			to_server_id = to_server_id, 
			session_id = session_id, 
			param = data.param
		}
		server_info:send_msg(MID.REMOTE_CALL_RET, msg)
		return
	end

	local param = Util.unserialize(data.param)
	RpcMgr.callback(session_id, result, param)

end

Net.add_msg_handler(MID.REMOTE_CALL_REQ, RpcMgr.handle_call)
Net.add_msg_handler(MID.REMOTE_CALL_RET, RpcMgr.handle_callback)

return RpcMgr
