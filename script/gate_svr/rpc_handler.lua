
local function gate_rpc_test(data)
	
	Log.debug("gate_rpc_test: data=%s", Util.table_to_string(data))

	local buff = data.buff
	local sum = data.sum

	buff = buff .. "3"
	sum = sum + 1

	return {result = ErrorCode.SUCCESS, buff=buff, sum=sum}
end

local function gate_rpc_nocb_test(data)
	Log.debug("gate_rpc_nocb_test: data=%s", Util.table_to_string(data))

	XXX_g_rpc_nocb_map = XXX_g_rpc_nocb_map or {}
	local buff = data.buff
	local index = data.index
	local sum = data.sum

	local last_sum = XXX_g_rpc_nocb_map[index]
	if not node then
		XXX_g_rpc_nocb_map[index] = sum
		return
	end

	if sum < last_sum then
		Log.err("gate_rpc_nocb_test bug index=%d sum=%d last_sum=%d", index, sum, last_sum)
		return
	end

	XXX_g_rpc_nocb_map[index] = sum

end

---------------------------------------------------------

local function gate_select_role(data)
	
	Log.debug("gate_select_role: data=%s", Util.table_to_string(data))

	local user_id = data.user_id
	local role_id = data.role_id
	local scene_id = data.scene_id
	local token = data.token
	
	local msg =
	{
		result = ErrorCode.SUCCESS,
		ip = "",
		port = 0,
	}

	-- check if already online
	local user = g_user_mgr:get_user_by_id(user_id)
	if user then
		if user:is_online() then
			-- duplicate select role
			Log.warn("gate_select_role: duplicate select role %d %d", user_id, role_id)
			msg.result = ErrorCode.SELECT_ROLE_DUPLICATE_LOGIN
			return msg
		end
		-- has user, but offline, just remove user 
		Log.debug("gate_select_role: user offline, del user user_id=%d old_role_id=%d new_role_id%d", user_id, user._role_id, role_id)
		g_user_mgr:del_user(user)
	end

	-- create user
	local User = require "gate_svr.user"
	user = User.new(user_id, role_id, scene_id, token)
	g_user_mgr:add_user(user)
	
	msg.result = ErrorCode.SUCCESS
	msg.ip = g_server_conf._ip
	msg.port = g_server_conf._port

	return msg
end

local function gate_check_role_online(data)
	
	Log.debug("gate_check_role_online: data=%s", Util.table_to_string(data))

	local user_id = data.user_id
	local role_id = data.role_id

	local msg =
	{
		is_online = false
	}

	local user = g_user_mgr:get_user_by_id(user_id)
	if not user then
		return msg
	end

	if role_id ~= user._role_id then
		return msg
	end

	msg.is_online = true
	return msg
end

local function register_rpc_handler()
	-- for test
	g_rpc_mgr:register_func("gate_rpc_test" ,gate_rpc_test)
	g_rpc_mgr:register_func("gate_rpc_nocb_test" ,gate_rpc_nocb_test)

	g_rpc_mgr:register_func("gate_select_role" ,gate_select_role)
	g_rpc_mgr:register_func("gate_check_role_online" ,gate_check_role_online)
end

register_rpc_handler()
