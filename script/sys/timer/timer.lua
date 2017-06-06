
Timer = {}

Timer._timer_mgr = {}

function Timer.add_timer(ms, cb_func, arg, is_loop)
	local timer_index, ret = add_timer_c(ms, is_loop)
	if not ret then
		return false
	end
	Timer._timer_mgr[timer_index] = { cb_func, arg }
	return timer_index, ret
end

function Timer.del_timer(timer_index)
	Timer._timer_mgr[timer_index] = nil
	return del_timer_c(timer_index)
end

function ccall_timer_handler(timer_index)
	local timer_param = Timer._timer_mgr[timer_index]
	if not timer_param then
		return
	end

	local function on_timer()
		timer_param[1](timer_param[2])
	end

	--local status, msg = xpcall(
end

return Timer
