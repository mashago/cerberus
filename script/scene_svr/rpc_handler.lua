
local function scene_rpc_test(data)
	Log.debug("scene_rpc_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local sum = data.sum

	buff = buff .. "4"
	sum = sum + 1

	return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
end

local function register_rpc_handler()
	g_rpc_mgr:register_func("scene_rpc_test", scene_rpc_test)
end

register_rpc_handler()
