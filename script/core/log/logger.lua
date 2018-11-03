
local cutil = require "cerberus.util"

local Log = {}

Log.LEVEL = 
{
	DEBUG = 1, 
	INFO = 2, 
	WARN = 3, 
	ERROR = 4,
}

local function log_handler(level, format, ...)
	local str = string.format("%s", string.format(format,...))
	cutil.log(level, str)
	if level == Log.LEVEL.ERROR then
		cutil.log(level, debug.traceback())
	end
end

local function log(level, format, ...)

	local status, err_msg = xpcall(log_handler
	, function(msg) return debug.traceback(msg, 3) end
	, level, format, ...)

	if not status then
		cutil.log(Log.LEVEL.ERROR, err_msg)
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
