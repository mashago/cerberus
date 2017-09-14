
local Role = {}

function Role:new(role_id, mailbox_id)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj._role_id = role_id
	obj._mailbox_id = mailbox_id -- router mailbox id

	return obj
end

function Role:send_msg(msg_id, msg)
	-- add role_id into ext
	return Net.send_msg_ext(self._mailbox_id, msg_id, self._role_id, msg)
end

function Role:load_db()
	
	local rpc_data = 
	{
		table_name = "role_info",
		fields = {},
		conditions = {role_id=role_id}
	}

	Log.debug("******** before load_db() rpc call")
	local status, ret = RpcMgr.call_by_server_type(ServerType.DB, "db_game_select", rpc_data)
	Log.debug("Role:load_db ret=%s", Util.table_to_string(ret))
	Log.debug("******** after load_db() rpc call")
	if not status then
		Log.err("Role:load_db fail")
		return false
	end

	if ret.result ~= ErrorCode.SUCCESS then
		Log.err("Role:load_db error %d", ret.result)
		return false
	end

	Log.debug("Role:load_db data=%s", Util.table_to_string(ret.data))

	if #ret.data ~= 1 then
		Log.err("Role:load_db data empty %d", ret.result)
		return false
	end

	return ret.data
end

function Role:serialize_to_record()
	-- memory data to db record
	local data = {}
	-- TODO

	return data
end

function Role:init_data(record)
	self._attr = {}
	local attr_map = self._attr
	for k, v in pairs(record) do
		attr_map[k] = v
	end
end

function Role:load_and_init_data()
	local record = self:load_db()
	if not record then
		return false
	end

	self:init_data(record)

	return true
end

function Role:send_module_data()
end

return Role
