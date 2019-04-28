
local net_mgr = require "net.net_mgr"
local Log = require "log.logger"

local HttpMgr = {
	_cur_session_id = 0,
	--[[
	{
		[session_id] = 
		{
			cb = cb,
		}
	}
	--]]
	_all_session_map = {},
}

function HttpMgr:gen_session_id()
	self._cur_session_id = self._cur_session_id + 1
	return self._cur_session_id
end

function HttpMgr:request_get(url, cb)
	local session_id = self:gen_session_id()
	self._all_session_map[session_id] = 
	{
		cb = cb,
	}
	net_mgr:http_request_get(url, session_id)
end

function HttpMgr:request_post(url, post_data, post_data_len, cb)
	local session_id = self:gen_session_id()
	self._all_session_map[session_id] = 
	{
		cb = cb,
	}
	net_mgr:http_request_post(url, session_id, post_data, post_data_len)
end

function HttpMgr:handle_request(session_id, response_code, content)
	Log.info("HttpMgr:handle_request session_id=%d response_code=%d len=%d content=%s", session_id, response_code, #content, content)

	local data = self._all_session_map[session_id]
	if not data then
		return
	end
	self._all_session_map[session_id] = nil

	local cb = data.cb
	if not cb then
		return
	end

	cb(response_code, content)
end

return HttpMgr
