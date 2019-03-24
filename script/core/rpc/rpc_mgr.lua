
local Core = require "core"
local Log = require "log.logger"
local Util = require "util.util"
local class = require "util.class"
local RPC_SEND_SESSION_ID = -1
local RPC_FIN_SESSION_ID = -2

local RpcMgr = class()

function RpcMgr:ctor()
	self._cur_session_id = 0
	self._all_session_map = {} -- {[session_id] = coroutine}
	self._origin_route_map = {} -- { [new_session_id] = {from_server_id=x, to_server_id=y, session_id=z} }

	self._running_call_env = nil
end

function RpcMgr:print()
	Log.warn("---- RpcMgr:print() ----")
	local all_session_map_size = 0
	for k, v in pairs(self._all_session_map) do
		all_session_map_size = all_session_map_size + 1
	end
	local origin_route_map_size = 0
	for k, v in pairs(self._origin_route_map) do
		origin_route_map_size = origin_route_map_size + 1
	end

	Log.warn("_cur_session_id=%s", self._cur_session_id)
	Log.warn("all_session_map_size=%s", all_session_map_size)
	Log.warn("origin_route_map_size=%s", origin_route_map_size)

	Log.warn("----")
end

--[[
if not call by send, MUST return a table
e.g.
for a normal rpc:
function rpc_mgr.mycb(data)
	... -- logic
	return { ... } -- return result
end)
for a send rpc:
function rpc_mgr.mysend(data)
	... -- logic
	-- nil return
end)
--]]

-- rpc warpper
function RpcMgr:run(func, ...)
	local cor = coroutine.create(func)
	local status, result = coroutine.resume(cor, ...)
	self._running_call_env = nil
	if not status then
		Log.err("RpcMgr:run: resume error %s", result)
		return
	end
	if not result then
		-- no rpc call inside, do nothing
		return
	end

	-- rpc call inside, result is a session_id
	assert(type(result) == "number", "RpcMgr:run: run result not a session_id")
	self._all_session_map[result] = cor	
end

function RpcMgr:ret(data)
	assert(type(data) == "table", "RpcMgr:ret data not a table")

	local running_call_env = self._running_call_env
	assert(running_call_env, "RpcMgr:ret running_call_env nil")
	assert(running_call_env.session_id ~= RPC_FIN_SESSION_ID
	, "RpcMgr:already ret error " .. running_call_env.session_id)

	local msg =
	{
		result = true, 
		from_server_id = running_call_env.from_server_id, 
		to_server_id = running_call_env.to_server_id, 
		session_id = running_call_env.session_id, 
		param = Util.serialize(data)
	}
	Core.net_mgr:send_msg(running_call_env.mailbox_id, MID.s2s_rpc_ret, msg)

	-- mark already call ret
	running_call_env.session_id = RPC_FIN_SESSION_ID
end

function RpcMgr:_gen_session_id()
	self._cur_session_id = self._cur_session_id + 1
	return self._cur_session_id
end

function RpcMgr:_gen_running_call_env(mailbox_id, from_server_id, to_server_id, session_id)
	return {
		mailbox_id = mailbox_id,
		from_server_id = from_server_id,
		to_server_id = to_server_id,
		session_id = session_id,
	}
end

-- rpc call function
function RpcMgr:call(server_info, func_name, data)
	local session_id = self:_gen_session_id()
	local msg = 
	{
		from_server_id = Core.server_conf._server_id, 
		to_server_id = server_info._server_id, 
		session_id = session_id, 
		func_name = func_name, 
		param = Util.serialize(data),
	}
	if not server_info:send_msg(MID.s2s_rpc_req, msg) then
		return false
	end
	return coroutine.yield(session_id)
end

function RpcMgr:call_by_server_type(server_type, func_name, data, opt_key)
	local server_info = Core.server_mgr:get_server_by_type(server_type, opt_key)
	if not server_info then return false end
	return self:call(server_info, func_name, data)
end

function RpcMgr:call_by_server_id(server_id, func_name, data)
	local server_info = Core.server_mgr:get_server_by_id(server_id)
	if not server_info then return false end
	return self:call(server_info, func_name, data)
end

-- async call, no yield, no callback
-- in sync coroutine will use same way to target server
function RpcMgr:send(server_info, func_name, data)
	local msg = 
	{
		from_server_id = Core.server_conf._server_id, 
		to_server_id = server_info._server_id, 
		session_id = RPC_SEND_SESSION_ID,
		func_name = func_name, 
		param = Util.serialize(data),
	}

	-- async call, will not yield
	return server_info:send_msg(MID.s2s_rpc_send_req, msg)
end

function RpcMgr:send_by_server_type(server_type, func_name, data, opt_key)
	local server_info = Core.server_mgr:get_server_by_type(server_type, opt_key)
	if not server_info then return false end
	return self:send(server_info, func_name, data)
end

function RpcMgr:send_by_server_id(server_id, func_name, data)
	local server_info = Core.server_mgr:get_server_by_id(server_id)
	if not server_info then return false end
	return self:send(server_info, func_name, data)
end

-- sync run a func in net thread
function RpcMgr:sync(func, ...)
	local session_id = self:_gen_session_id()
	func(session_id, ...)
	local _, data = coroutine.yield(session_id)
	return table.unpack(data)
end

---------------------------------------

local function send_error_ret(mailbox_id, from_server_id, to_server_id, session_id, errno)
	local msg =
	{
		result = false, 
		from_server_id = from_server_id, 
		to_server_id = to_server_id, 
		session_id = session_id, 
		param = tostring(errno),
	}
	Core.net_mgr:send_msg(mailbox_id, MID.s2s_rpc_ret, msg)
end

function RpcMgr:_call(data, mailbox_id, msg_id, is_send)
	
	local from_server_id = data.from_server_id
	local to_server_id = data.to_server_id
	local session_id = data.session_id
	local func_name = data.func_name

	self._running_call_env = self:_gen_running_call_env(mailbox_id, from_server_id, to_server_id, session_id)

	-- server_id mismatch
	if to_server_id ~= Core.server_conf._server_id then
		Log.err("RpcMgr:_call server_id mismatch to_server_id=%d local_server_id=%d", to_server_id, Core.server_conf._server_id)
		if not is_send then
			send_error_ret(mailbox_id, from_server_id, to_server_id, session_id, -1)

		end
		return
	end

	-- handle rpc
	local param = Util.unserialize(data.param)
	local func = self[func_name]
	if not func then
		Log.err("RpcMgr:_call func not exists %s", func_name)
		if not is_send then
			send_error_ret(mailbox_id, from_server_id, to_server_id, session_id, -1)
		end
		return
	end

	-- consider rpc in call function
	-- so use a coroutine wrap this function
	local cor = coroutine.create(func)
	local status, result = coroutine.resume(cor, param, mailbox_id)
	session_id = self._running_call_env.session_id -- update session_id, may change in ret
	if not status then
		Log.err("RpcMgr:_call resume function error func_name=%s %s", func_name, result)
		if not is_send and session_id ~= RPC_FIN_SESSION_ID then
			send_error_ret(mailbox_id, from_server_id, to_server_id, session_id, -1)
		end
		return
	end

	-- result only can be number, table, (nil for send)
	if type(result) == "number" then

		-- has rpc inside, result is a session_id
		-- mark down this coroutine and session_id
		local new_session_id = result
		self._all_session_map[new_session_id] = cor	

		-- mark down the route back to caller
		if not is_send and session_id ~= RPC_FIN_SESSION_ID then
			local origin_route = self._running_call_env
			origin_route.func_name = func_name -- only for err print
			self._origin_route_map[new_session_id] = origin_route
		end
	else
		-- function over, check if call ret
		if not is_send and session_id ~= RPC_FIN_SESSION_ID then
			Log.err("RpcMgr:_call miss ret func_name=%s", func_name)
			send_error_ret(mailbox_id, from_server_id, to_server_id, session_id, -1)
		end
	end
end

function RpcMgr:handle_call(data, mailbox_id, msg_id, is_send)
	self:_call(data, mailbox_id, msg_id, is_send)
	self._running_call_env = nil
end

function RpcMgr:_callback(session_id, result, data)

	local cor = self._all_session_map[session_id]
	if not cor then
		Log.warn("RpcMgr:_callback cor nil session_id=%d", session_id)
		return
	end
	self._all_session_map[session_id] = nil	

	-- for rpc:ret if necessary
	local origin_route = self._origin_route_map[session_id]
	if origin_route then
		self._running_call_env = origin_route
		local server_info = Core.server_mgr:get_server_by_id(origin_route.from_server_id)
		if server_info then
			self._running_call_env.mailbox_id = server_info:get_mailbox_id()
		else
			-- let it go, fail in send_msg back
			Log.err("RpcMgr:_callback cannot go back from_server_id=%d", origin_route.from_server_id)
			self._running_call_env.mailbox_id = MAILBOX_ID_NIL
		end
	end

	local status
	status, result = coroutine.resume(cor, result, data)
	if not status then
		Log.err("RpcMgr:_callback: cor resume error %s", result)
		return
	end

	if type(result) == "number" then
		-- another rpc inside
		local new_session_id = result
		self._all_session_map[new_session_id] = cor	

		-- if has origin_route, fix to new session id
		if origin_route then
			self._origin_route_map[session_id] = nil
			self._origin_route_map[new_session_id] = origin_route
		end
	else
		-- function over, check if call ret
		if origin_route then
			-- it is a call
			if self._running_call_env.session_id ~= RPC_FIN_SESSION_ID then
				Log.err("RpcMgr:_callback miss ret func_name=%s", origin_route.func_name)
				send_error_ret(self._running_call_env.mailbox_id
				, self._running_call_env.from_server_id
				, self._running_call_env.to_server_id
				, self._running_call_env.session_id, -1)
			end
			self._origin_route_map[session_id] = nil
		end
	end

end

function RpcMgr:handle_callback(data, mailbox_id, msg_id)
	local result = data.result
	local session_id = data.session_id
	local from_server_id = data.from_server_id
	-- local to_server_id = data.to_server_id

	-- server_id mismatch
	if from_server_id ~= Core.server_conf._server_id then
		Log.err("RpcMgr:handle_callback server_id mismatch from_server_id=%d local_server_id=%d", from_server_id, Core.server_conf._server_id)
		return
	end

	local param = Util.unserialize(data.param)
	self:_callback(session_id, result, param)
	self._running_call_env = nil
end

function RpcMgr:handle_local_callback(session_id, ...)
	self:_callback(session_id, true, {...})
	self._running_call_env = nil
end

return RpcMgr
