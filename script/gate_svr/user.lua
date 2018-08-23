local Env = require "env"
local Log = require "core.log.logger"
local g_funcs = require "core.global.global_funcs"
local class = require "core.util.class"

local MAILBOX_ID_NIL = MAILBOX_ID_NIL
local MID = MID

local User = class()

function User:ctor(user_id, role_id, scene_id, token)
	self._user_id = user_id
	self._role_id = role_id
	self._scene_id = scene_id
	self._token = token

	self._scene_server_id = 0
	self._mailbox_id = MAILBOX_ID_NIL
end

function User:is_online()
	return self._mailbox_id ~= MAILBOX_ID_NIL
end

function User:send_msg(msg_id, msg)
	if self._mailbox_id == MAILBOX_ID_NIL then
		Log.warn("User:send_msg mailbox_id nil msg_id=%s", g_funcs.get_msg_name(msg_id))
		return false
	end
	return Env.net_mgr:send_msg(self._mailbox_id, msg_id, msg)
end

function User:transfer_msg()
	return Env.net_mgr:transfer_msg(self._mailbox_id)
end

function User:offline()
	-- clear mailbox_id
	-- send to scene server

	self._mailbox_id = MAILBOX_ID_NIL

	local scene_server_info = Env.server_mgr:get_server_by_id(self._scene_server_id)
	if not scene_server_info then
		Log.err("User:disconnect: scene server not exists scene_id=%d", self._scene_server_id)
		return
	end
	local msg = { }
	scene_server_info:send_msg_ext(MID.s2s_gate_role_disconnect, self._role_id, msg)
end

return User
