
function send_to_server(server_type, msg_id, ...)
		
	local server_list = ServiceClient._type_server_map[server_type] or {}
	if #server_list == 0 then
		return nil
	end
	local server_id = server_list[1]

	local server_info = ServiceClient._all_server_map[server_id]
	if not server_info then
		return
	end

	local mailbox_id = server_info._service_mailbox_list[1] or 0
	if mailbox_id == 0 then
		return
	end

	Net.send_msg(mailbox_id, msg_id, ...)
end

function send_to_login(msg_id, ...)
	ServiceClient.send_to_type_server(ServerType.LOGIN, msg_id, ...)
end

function send_to_router(msg_id, ...)
	ServiceClient.send_to_type_server(ServerType.ROUTER, msg_id, ...)
end

local function handle_user_login(data, mailbox_id, msg_id)
	Log.debug("handle_user_login: data=%s", Util.TableToString(data))
end

function register_msg_handler()
	Net.add_msg_handler(MID.USER_LOGIN_RET, handle_user_login)
end
