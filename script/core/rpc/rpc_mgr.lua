
local Core = require "core"
local Log = require "core.log.logger"
local Util = require "core.util.util"
local class = require "core.util.class"
local RPC_NOCB_SESSION_ID = -1

local RpcMgr = class()

function RpcMgr:ctor()
	self._cur_session_id = 0
	self._all_session_map = {} -- {[session_id] = coroutine}
	self._origin_route_map = {} -- { [new_session_id] = {from_server_id=x, to_server_id=y, session_id=z} }
end

function RpcMgr:print()
	Log.warn("---- RpcMgr:print() ----")
	local all_session_map_size = 0
	for k, v in pairs(self._all_session_map) do
		all_session_map_size = all_session_map_size + 1
	end
	local oringin_route_map_size = 0
	for k, v in pairs(self._origin_route_map) do
		oringin_route_map_size = oringin_route_map_size + 1
	end

	Log.warn("_cur_session_id=%s", self._cur_session_id)
	Log.warn("all_session_map_size=%s", all_session_map_size)
	Log.warn("oringin_route_map_size=%s", oringin_route_map_size)

	Log.warn("----")
end

--[[
if not call by nocb, MUST return a table
e.g.
for a normal rpc:
function rpc_mgr.mycb(data)
	... -- logic
	return { ... } -- return result
end)
for a nocb rpc:
function rpc_mgr.mynocb(data)
	... -- logic
	-- nil return
end)
--]]

-- rpc warpper
function RpcMgr:run(func, ...)
	local cor = coroutine.create(func)
	local status, result = coroutine.resume(cor, ...)
	if not status then
		Log.err("RpcMgr:run: resume error %s", result)
		return
	end
	if not result then
		-- no rpc inside, do nothing
		return
	end

	if type(result) ~= "number" then
		Log.err("RpcMgr:run: run result not a session_id")
		return
	end

	local session_id = result
	-- return session_id if has rpc inside
	self._all_session_map[session_id] = cor	
end

function RpcMgr:gen_session_id()
	self._cur_session_id = self._cur_session_id + 1
	return self._cur_session_id
end

-- rpc call function
function RpcMgr:call(server_info, func_name, data)
	local session_id = self:gen_session_id()
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
function RpcMgr:call_nocb(server_info, func_name, data)
	local msg = 
	{
		from_server_id = Core.server_conf._server_id, 
		to_server_id = server_info._server_id, 
		session_id = RPC_NOCB_SESSION_ID,
		func_name = func_name, 
		param = Util.serialize(data),
	}

	-- async call, will not yield
	return server_info:send_msg(MID.s2s_rpc_nocb_req, msg)
end

function RpcMgr:call_nocb_by_server_type(server_type, func_name, data, opt_key)
	local server_info = Core.server_mgr:get_server_by_type(server_type, opt_key)
	if not server_info then return false end
	return self:call_nocb(server_info, func_name, data)
end

function RpcMgr:call_nocb_by_server_id(server_id, func_name, data)
	local server_info = Core.server_mgr:get_server_by_id(server_id)
	if not server_info then return false end
	return self:call_nocb(server_info, func_name, data)
end

---------------------------------------

function RpcMgr:handle_call(data, mailbox_id, msg_id, is_nocb)
	local from_server_id = data.from_server_id
	local to_server_id = data.to_server_id
	local session_id = data.session_id
	local func_name = data.func_name

	local function send_error(errno)
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

	-- server_id mismatch
	if to_server_id ~= Core.server_conf._server_id then
		Log.err("RpcMgr:handle_call server_id mismatch to_server_id=%d local_server_id=%d", to_server_id, Core.server_conf._server_id)
		if not is_nocb then
			send_error(-1)
		end
		return
	end

	-- handle rpc
	local param = Util.unserialize(data.param)
	local func = self[func_name]
	if not func then
		Log.err("RpcMgr:handle_call func not exists %s", func_name)
		if not is_nocb then
			send_error(-1)
		end
		return
	end

	-- consider rpc in call function
	-- so use a coroutine wrap this function
	local cor = coroutine.create(func)
	local status, result = coroutine.resume(cor, param, mailbox_id)
	if not status then
		Log.err("RpcMgr:handle_call resume function error func_name=%s %s", func_name, result)
		if not is_nocb then
			send_error(-1)
		end
		return
	end

	-- result only can be number, table, (nil for nocb)
	if type(result) == "number" then
		-- has rpc inside, result is a session_id
		-- mark down this coroutine and session_id
		local new_session_id = result
		self._all_session_map[new_session_id] = cor	

		-- mark down the route back to caller
		if not is_nocb then
			local origin_route = 
			{
				from_server_id = from_server_id,
				to_server_id = to_server_id,
				session_id = session_id,
				func_name = func_name, -- only for err print
			}
			self._origin_route_map[new_session_id] = origin_route
		end
		return
	elseif is_nocb then
		-- rpc nocb done
		return
	elseif type(result) == "table" then
		-- result is a table, no rpc inside, just send back result
		local msg =
		{
			result = true, 
			from_server_id = from_server_id, 
			to_server_id = to_server_id, 
			session_id = session_id, 
			param = Util.serialize(result)
		}
		Core.net_mgr:send_msg(mailbox_id, MID.s2s_rpc_ret, msg)
		return
	else
		-- else is error
		Log.err("RpcMgr:handle_call resume result error func_name=%s type(result)=%s", func_name, type(result))
		send_error(-1)
		return
	end
end


function RpcMgr:callback(session_id, result, data)

	local cor = self._all_session_map[session_id]
	if not cor then
		Log.warn("RpcMgr:callback cor nil session_id=%d", session_id)
		return
	end
	self._all_session_map[session_id] = nil	

	local status
	status, result = coroutine.resume(cor, result, data)
	if not status then
		Log.err("RpcMgr:callback: cor resume error %s", result)
		return
	end

	if type(result) == "number" then
		-- another rpc inside
		local new_session_id = result
		self._all_session_map[new_session_id] = cor	

		-- if has origin_route, fix to new session id
		local origin_route = self._origin_route_map[session_id]
		if origin_route then
			self._origin_route_map[session_id] = nil
			self._origin_route_map[new_session_id] = origin_route
		end
		return
	end

	-- rpc finish
	-- check if this callback is a rpc from otherwhere
	local origin_route = self._origin_route_map[session_id]
	if not origin_route then
		-- not from a rpc or is a rpc nocb
		return
	end
	self._origin_route_map[session_id] = nil
	assert(origin_route.session_id ~= RPC_NOCB_SESSION_ID)

	local server_info = Core.server_mgr:get_server_by_id(origin_route.from_server_id)
	if not server_info then
		Log.warn("RpcMgr:callback cannot go back from_server_id=%d", origin_route.from_server_id)
		return
	end

	if type(result) ~= "table" then
		Log.err("RpcMgr:callback result error func_name=%s type(result)=%s", origin_route.func_name, type(result))
		return
	end

	local msg =
	{
		result = true, 
		from_server_id = origin_route.from_server_id, 
		to_server_id = origin_route.to_server_id, 
		session_id = origin_route.session_id, 
		param = Util.serialize(result)
	}
	server_info:send_msg(MID.s2s_rpc_ret, msg)

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
	self:callback(session_id, result, param)

end

return RpcMgr
