

local function read_msg_by_def(msgdef, deep)
end

local function recv_msg(msg_id)
	local def = MSG_DEF_MAP[msg_id]
	if not def then
		print("recv_msg(msg_id) def not exists")
		return
	end

	local flag, msg = read_msg_by_def(def, 0)
	return flag, msg
end


local function recv_msg_handler(mailbox_id, msg_id)
	local flag, msg = recv_msg(msg_id)	
	
end

local function error_handler(msg, mailbox_id, msg_id)
end

function ccall_net_recv_msg_handler(mailbox_id, msg_id)
	print("mailbox_id=", mailbox_id, " msg_id=", msg_id)
	local msg_name = MID._id_name_map[msgId]
	print("msg_name=", msg_name)
	
	local status = xpcall(recv_msg_handler
	, function(msg) return error_handler(msg, mailbox_id, msg_id) end
	, mailbox_id, msg_id)

end
