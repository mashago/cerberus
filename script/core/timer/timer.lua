
local Core = require "core"
local Log = require "core.log.logger"
local class = require "core.util.class"
local Timer = class()

function Timer:ctor()
	self._timer_index_map = {}
end

function Timer:add_timer(ms, cb_func, arg, is_loop)
	local timer_index, ret = LuaTimer:add_timer(ms, is_loop)
	if not ret then
		return false
	end
	self._timer_index_map[timer_index] = { cb_func, arg }
	return timer_index
end

function Timer:del_timer(timer_index)
	if not timer_index or type(timer_index) ~= 'number' then
		Log.err("Timer:del_timer timer_index err %s", type(timer_index))
		return false
	end
	self._timer_index_map[timer_index] = nil
	return LuaTimer:del_timer(timer_index)
end

function Timer:on_timer(timer_index, is_loop)
	local timer_param = self._timer_index_map[timer_index]
	if not timer_param then
		Log.err("Timer:on_timer timer not existas %d", timer_index)
		return
	end
	if not is_loop then
		self._timer_index_map[timer_index] = nil
	end

	local function wrapper()
		-- timer_param[1](timer_param[2])
		Core.rpc_mgr:run(timer_param[1], timer_param[2])
	end

	local function error_handler(msg)
		local msg = debug.traceback(msg, 3)
		msg = string.format("Timer:on_timer timer_index=%d\n%s", timer_index, msg)
		return msg
	end

	local status, msg = xpcall(wrapper, error_handler)
	if not status then
		Log.err(msg)
	end
end

return Timer
