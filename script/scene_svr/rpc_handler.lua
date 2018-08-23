
local Env = require "env"
local rpc_mgr = Env.rpc_mgr
local Log = require "core.log.logger"
local Util = require "core.util.util"
local ErrorCode = ErrorCode

function rpc_mgr.scene_rpc_test(data)
	Log.debug("scene_rpc_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local sum = data.sum

	buff = buff .. "4"
	sum = sum + 1

	return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
end

local XXX_g_rpc_nocb_map = {}
function rpc_mgr.scene_rpc_nocb_test(data)
	Log.debug("scene_rpc_nocb_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local index = data.index
	local sum = data.sum

	local last_sum = XXX_g_rpc_nocb_map[index]
	if not last_sum then
		XXX_g_rpc_nocb_map[index] = sum
		return
	end

	if sum < last_sum then
		Log.err("scene_rpc_nocb_test bug index=%d sum=%d last_sum=%d", index, sum, last_sum)
		return
	end

	XXX_g_rpc_nocb_map[index] = sum

end

