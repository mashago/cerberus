
local Log = require "core.log.logger"
local class = require "core.util.class"

local TimeCounter = class()

function TimeCounter:ctor()
	self._start_time = 0
end

function TimeCounter:start()
	self._start_time = LuaUtil:get_time_ms()
end

function TimeCounter:print()
	local end_time = LuaUtil:get_time_ms()
	Log.debug("******* use time=%fms", end_time - self._start_time)
end

return TimeCounter
