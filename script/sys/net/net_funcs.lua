
Net = {}
Net._msg_handler_map = {}

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

