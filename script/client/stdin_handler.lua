
function handle_cmd(buffer)
	Log.debug("buffer=%s", buffer)
	local params = Util.SplitString(buffer, " ")
	Log.debug("params=%s", Util.TableToString(params))
end

function ccall_stdin_handler(buffer)
	Log.info("ccall_stdin_handler buffer=%s", buffer)

	local function error_handler(msg)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_stdin_handler error : \n%s", msg)
		return msg 
	end
	
	local status, msg = xpcall(handle_cmd
	, function(msg) return error_handler(msg) end
	, buffer)

	if not status then
		Log.err(msg)
	end
end
