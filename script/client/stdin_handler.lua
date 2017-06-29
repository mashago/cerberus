
local cmd_handler = {}

function cmd_handler.execute(buffer)
	Log.debug("buffer=%s", buffer)
	local params = Util.SplitString(buffer, " ")
	Log.debug("params=%s", Util.TableToString(params))

	if params[1] == "login" then
		cmd_handler.do_login(params)
	elseif params[1] == "loginx" then
		cmd_handler.do_loginx(params)
	elseif params[1] == "create" then
		cmd_handler.do_create_role(params)
	elseif params[1] == "rpc" then
		cmd_handler.do_rpc_test(params)
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

g_loginx_num = 0
g_loginx_start_time = 0
function cmd_handler.do_loginx(params)
	-- loginx [num]
	if #params ~= 2 then
		Log.warn("cmd_handler.do_loginx params not enough")
		return
	end

	local num = tonumber(params[2])

	for i=1, num do
		local x = math.random(1000000)
		local username = "test" .. tostring(x)
		send_to_login(MID.USER_LOGIN_REQ, username, "qwerty")
	end

	g_loginx_num = num
	g_loginx_start_time = os.time()

end

function cmd_handler.do_create_role(params)
	-- create [role_name]
	if #params ~= 2 then
		Log.warn("cmd_handler.do_create_role params not enough")
		return
	end

	send_to_login(MID.CREATE_ROLE_REQ, params[2])
end

function cmd_handler.do_rpc_test(params)
	-- rpc [buff]
	if #params ~= 2 then
		Log.warn("cmd_handler.do_rpc_test params not enough")
		return
	end

	send_to_login(MID.RPC_TEST_REQ, params[2])
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
