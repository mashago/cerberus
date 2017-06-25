

function register_rpc_handler()

	local call_func_map = RpcMgr._all_call_func

	call_func_map.router_create_role = function(data)
		
		Log.debug("router_create_role: data=%s", Util.TableToString(data))

		-- TODO send to scene server to create role

		local role_id = data.role_id
		local role_name = data.role_name

		-- must return a table
		return {result = 1, role_id = role_id, role_name = role_name}
	end
end
