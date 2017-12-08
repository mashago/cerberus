
Timer = {}

Timer._timer_mgr = {}

function Timer.add_timer(ms, cb_func, arg, is_loop)
	local timer_index, ret = add_timer_c(g_luaworld_ptr, ms, is_loop)
	if not ret then
		return false
	end
	Timer._timer_mgr[timer_index] = { cb_func, arg }
	return timer_index, ret
end

function Timer.del_timer(timer_index)
	Timer._timer_mgr[timer_index] = nil
	return del_timer_c(g_luaworld_ptr, timer_index)
end

function ccall_timer_handler(timer_index)
	timer_index = math.floor(timer_index)
	-- Log.debug("timer_index=%d", timer_index)
	local timer_param = Timer._timer_mgr[timer_index]
	if not timer_param then
		return
	end

	local function on_timer()
		timer_param[1](timer_param[2])
	end

	local function error_handler(msg)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_timer_handler timer_index=%d\n%s", timer_index, msg)
		return msg
	end

	local status, msg = xpcall(on_timer, error_handler)
	if not status then
		Log.err(msg)
	end
end

return Timer
