local Core = require "core"
local Log = require "log.logger"
local Util = require "util.util"
local g_msg_handler = require "global.msg_handler"
local Env = require "env"

------------------------------------------------

function g_msg_handler.s2c_rpc_test_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_rpc_test_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_rpc_test_ret: result=%s", ErrorCodeText[data.result])
	end
	Env.client:x_test_end()
end

function g_msg_handler.s2c_user_login_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_user_login_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_user_login_ret: result=%s", ErrorCodeText[data.result])
	end
	Env.client:x_test_end()
end

function g_msg_handler.s2c_user_kick(data)
	Core.server_mgr:close_connection_by_type(ServerType.LOGIN, true)
end

function g_msg_handler.s2c_area_list_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_area_list_ret: data=%s", Util.table_to_string(data))

	Env.time_counter:print()
end

function g_msg_handler.s2c_role_list_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_role_list_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_role_list_ret: result=%s", ErrorCodeText[data.result])
	end

	Env.client._area_role_list = data.area_role_list
	Env.time_counter:print()
end

function g_msg_handler.s2c_create_role_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_create_role_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_create_role_ret: result=%s", ErrorCodeText[data.result])
	end

	Env.time_counter:print()
end

function g_msg_handler.s2c_delete_role_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_delete_role_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_delete_role_ret: result=%s", ErrorCodeText[data.result])
	end

	Env.time_counter:print()
end

function g_msg_handler.s2c_select_role_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_select_role_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_select_role_ret: result=%s", ErrorCodeText[data.result])
		return
	end

	Env.client._server_list[ServerType.GATE] =
	{
		ip = data.ip,
		port = data.port,
		server_id = 1, -- no same with login is ok
	}

	Env.client._user_id = data.user_id
	Env.client._user_token = data.token

	Env.time_counter:print()
	Core.server_mgr:close_connection_by_type(ServerType.LOGIN, true)
end

function g_msg_handler.s2c_role_enter_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_role_enter_ret: data=%s", Util.table_to_string(data))
	if data.result ~= ErrorCode.SUCCESS then
		Log.warn("s2c_role_enter_ret: result=%s", ErrorCodeText[data.result])
	end

	Env.time_counter:print()
end

function g_msg_handler.s2c_role_attr_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_role_attr_ret: data=%s", Util.table_to_string(data))

	local role_id = data.role_id
	local attr_table = data.attr_table

	local Role = require "client.role"
	Env.role = Role.new(role_id)
	Env.role:init_data(attr_table)
	Env.role:print()
end

function g_msg_handler.s2c_role_attr_change_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_role_attr_change_ret: data=%s", Util.table_to_string(data))
	
	local attr_table = data.attr_table
	if Env.role then
		Env.role:update_data(attr_table)
		Env.role:print()
	end
end

function g_msg_handler.s2c_attr_info_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_attr_info_ret: data=%s", Util.table_to_string(data))

	local sheet_name = data.sheet_name
	if sheet_name == "role_info" then
		if not Env.role then
			local Role = require "client.role"
			Env.role = Role.new()
		end
		Env.role:init_data(data.rows[1])
		Env.role:print()
	end
end

function g_msg_handler.s2c_attr_insert_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_attr_insert_ret: data=%s", Util.table_to_string(data))
end

function g_msg_handler.s2c_attr_delete_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_attr_delete_ret: data=%s", Util.table_to_string(data))
end

function g_msg_handler.s2c_attr_modify_ret(data, mailbox_id, msg_id)
	Log.debug("s2c_attr_modify_ret: data=%s", Util.table_to_string(data))

	local sheet_name = data.sheet_name
	if sheet_name == "role_info" then
		if not Env.role then
			return
		end
		Env.role:update_data(data.rows[1].attrs)
		Env.role:print()
	end

	Env.client:x_test_end()
end

function g_msg_handler.s2c_role_kick(data, mailbox_id, msg_id)
	Core.server_mgr:close_connection_by_type(ServerType.GATE, true)
end

