

local TimeCounter = class()

function TimeCounter:ctor()
	self._start_time = 0
end

function TimeCounter:start()
	self._start_time = get_time_ms_c()
end

function TimeCounter:print()
	local end_time = get_time_ms_c()
	Log.debug("******* use time=%fms", end_time - self._start_time)
end

return TimeCounter
