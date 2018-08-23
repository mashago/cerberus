
local Log = {}

Log.LEVEL = 
{
	DEBUG = 1, 
	INFO = 2, 
	WARN = 3, 
	ERROR = 4,
}

local function log(level, format, ...)
	local function log_handler(level, format, ...)
		local str = string.format("%s", string.format(format,...))
		LuaUtil:log(level, str)
		if level == Log.LEVEL.ERROR then
			LuaUtil:log(level, debug.traceback())
		end
	end

	local status, err_msg = xpcall(log_handler
	, function(msg) return debug.traceback(msg, 3) end
	, level, format, ...)

	if not status then
		LuaUtil:log(Log.LEVEL.ERROR, err_msg)
	end  
end

function Log.debug(format,...)
	log(Log.LEVEL.DEBUG, format, ...)
end

function Log.info(format,...)
	log(Log.LEVEL.INFO, format, ...)
end

function Log.warn(format,...)
	log(Log.LEVEL.WARN, format, ...)
end

function Log.err(format,...)
	log(Log.LEVEL.ERROR, format, ...)
end

return Log
