
Net = {}
Net._msg_handler_map = {}
Net._all_mailbox = {} -- {mailbox_id=x, conn_type=y}

function Net.send_msg(mailbox_id, msg_id, ...)
	local msgdef = MSG_DEF_MAP[msg_id]
	if not msgdef then
		Log.err("Net.send_msg msgdef not exists msg_id=%d", msg_id)
		return false
	end

	local args = {...}
	if #msgdef ~= #args then
		Log.err("Net.send_msg args count error msg_id=%d", msg_id)
		return false
	end

	local flag = write_data_by_msgdef(args, msgdef, 0)
	if not flag then
		Log.err("Net.send_msg write data error msg_id=%d", msg_id)
		return false
	end

	g_network:write_msg_id(msg_id)
	return g_network:send(mailbox_id)
end

function Net.add_msg_handler(msg_id, func)
	local f = Net._msg_handler_map[msg_id]
	if f then
		print("Net.add_msg_handler duplicate ", msg_id)
	end
	Net._msg_handler_map[msg_id] = func
end

function Net.get_msg_handler(msg_id)
	return Net._msg_handler_map[msg_id]
end

function Net.add_mailbox(mailbox_id, conn_type)
	table.insert(Net._all_mailbox, {mailbox_id=mailbox_id, conn_type=conn_type})
end

function Net.get_mailbox(mailbox_id)
	return Net._all_mailbox[mailbox_id]	
end

function Net.del_mailbox(mailbox_id)
	Net._all_mailbox[mailbox_id] = nil
end

