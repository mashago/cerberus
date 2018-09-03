local Log = require "core.log.logger"
local class = require "core.util.class"
local Util = require "core.util.util"

local ServerConfig = class()

function ServerConfig:ctor(config)

	self._config = config
	self._all_scene_list = {}
	self._single_scene_list = {}
	self._from_to_scene_list = {}
	self._area_list = {}
	self._no_broadcast = false

	self._mysql_list = {}
	self._db_name_map = {} -- {[db_type]=db_name}

	
	local s = config.server[1]

	self._server_id = tonumber(s.id or 0)
	self._server_type = tonumber(s.type or 0)
	self._ip = s.ip or ""
	self._port = tonumber(s.port or 0)

	self._path = assert(s.path)

	-- load connect_to server list
	local address = ((s.connect_to or {})[1] or {}).address or {}
	self._connect_to = {}
	for _, v in ipairs(address) do
		table.insert(self._connect_to, 
		{
			ip = v.ip,
			port = tonumber(v.port),
		})
	end

	-- load scene list
	local scene = ((s.scene_list or {})[1] or {}).scene or {}
	for _, v in ipairs(scene) do
		local single = tonumber(v.single or 0)
		local from = tonumber(v.from or 0)
		local to = tonumber(v.to or 0)

		if single > 0 then
			assert(not self._all_scene_list[single], "ServerConfig duplicate single=" .. single)
			table.insert(self._single_scene_list, single)
			self._all_scene_list[single] = single
		end

		if from < to then
			assert(not (self._all_scene_list[from] or self._all_scene_list[to]), "ServerConfig duplicate from to=", from .. " " .. to)
			table.insert(self._from_to_scene_list, from)
			table.insert(self._from_to_scene_list, to)
			for i=from, to do
				self._all_scene_list[i] = i
			end
		end
	end

	-- load area list
	local area = ((s.area_list or {})[1] or {}).area or {}
	local t = {}
	for _, v in ipairs(area) do
		local area_id = tonumber(v.id or 0)
		assert(not t[area_id], "ServerConfig duplicate area_id=" .. area_id)
		table.insert(self._area_list, area_id)
	end

	-- load mysqldb list
	local mysql = ((s.mysql or {})[1] or {}).info or {}
	for _, v in ipairs(mysql) do
		local db_type = tonumber(v.db_type)
		local db_name = v.db_name
		local db_suffix = v.db_suffix or ""
		local real_db_name = db_name .. db_suffix
		table.insert(self._mysql_list, 
		{
			ip = v.ip or "",
			port = tonumber(v.port),
			username = v.username,
			password = v.password,
			db_type = db_type,
			db_name = db_name,
			db_suffix = db_suffix,
			real_db_name = real_db_name,
		})
		self._db_name_map[db_type] = real_db_name
	end
	
end

function ServerConfig:print()
	Log.debug("\n@@@@@@@ ServerConfig @@@@@@@")
	Log.debug("_server_id=%d _server_type=%d", self._server_id, self._server_type)
	Log.debug("_ip=%s _port=%d", self._ip, self._port)
	Log.debug("_connect_to=%s", Util.table_to_string(self._connect_to))
	Log.debug("@@@@@@@\n")

end

return ServerConfig
