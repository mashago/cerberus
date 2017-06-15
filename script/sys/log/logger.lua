
Log = {}

Log.LEVEL = {DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4}

local function log(level, format, ...)
	local function log_level2str(log_level)
		local ret = "NOT DEFINE LEVEL"
		if log_level == Log.LEVEL.DEBUG then
			ret = "[DEBUG]"
		elseif log_level == Log.LEVEL.INFO then
			ret = "[INFO]"
		elseif log_level == Log.LEVEL.WARN then
			ret = "[WARN]"
		elseif log_level == Log.LEVEL.ERROR then
			ret = "[ERROR]"
		end
		return ret
	end

	local function log_handler(level, format, ...)
		local now_date = os.date("*t")
		local time_string = string.format("[%02d:%02d:%02d]", now_date.hour, now_date.min, now_date.sec)
		print(string.format("%s %s : %s", log_level2str(level), time_string, string.format(format,...)))
		if level == Log.LEVEL.ERROR then
			print(debug.traceback())
		end
	end

	local status, err_msg = xpcall(
	-- function(...) log_handler(...) end
	log_handler
	, function(msg) return debug.traceback(msg, 3) end
	, level, format, ...)

	if not status then
		Log.err(err_msg)
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
