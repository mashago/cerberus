
local cmd_handler = {}

function cmd_handler.execute(buffer)
	Log.debug("buffer=%s", buffer)
	local params = Util.SplitString(buffer, " ")
	Log.debug("params=%s", Util.TableToString(params))

	if params[1] == "login" then
		cmd_handler.do_login(params)
	end

end

function cmd_handler.do_login(params)
	-- login [username] [password]
	if #params ~= 3 then
		Log.warn("cmd_handler.do_login params not enough")
		return
	end

	send_to_login(MID.USER_LOGIN_REQ, params[2], params[3])
end

function ccall_stdin_handler(buffer)
	Log.info("ccall_stdin_handler buffer=%s", buffer)

	local function error_handler(msg)
		local msg = debug.traceback(msg, 3)
		msg = string.format("ccall_stdin_handler error : \n%s", msg)
		return msg 
	end
	
	local status, msg = xpcall(cmd_handler.execute
	, function(msg) return error_handler(msg) end
	, buffer)

	if not status then
		Log.err(msg)
	end
end

return cmd_handler
