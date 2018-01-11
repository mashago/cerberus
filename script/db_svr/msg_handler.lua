
local function handle_db_delete(data, mailbox_id, msg_id)
	Log.debug("handle_db_delete: data=%s", Util.table_to_string(data))

	local db_name = data.db_name
	local table_name = data.table_name
	local conditions = Util.unserialize(data.conditions)
	Log.debug("handle_db_delete conditions=%s", Util.table_to_string(conditions))

	local ret = DBMgr.do_delete(db_name, table_name, conditions)

	Log.debug("handle_db_delete ret=%d", ret)
end

local function register_msg_handler()
	Net.add_msg_handler(MID.SHAKE_HAND_REQ, g_funcs.handle_shake_hand_req)
	Net.add_msg_handler(MID.SHAKE_HAND_RET, g_funcs.handle_shake_hand_ret)
	Net.add_msg_handler(MID.SHAKE_HAND_INVITE, g_funcs.handle_shake_hand_invite)

	Net.add_msg_handler(MID.DB_DELETE, handle_db_delete)
end

register_msg_handler()
