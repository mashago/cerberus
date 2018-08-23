
local class = require "core.util.class"
local AreaMgr = class()

function AreaMgr:ctor()
	self._area_map = {} -- {[area_id]=[server_id], ...}
end

function AreaMgr:register_area(server_id, area_list)
	for _, area_id in ipairs(area_list) do
		if self._area_map[area_id] then
			-- multi server register same area
			return false
		end
	end

	for _, area_id in ipairs(area_list) do
		self._area_map[area_id] = server_id
	end
	return true
end

function AreaMgr:is_open(area_id)
	if not self._area_map[area_id] then
		return false
	end
	return true
end

function AreaMgr:get_server_id(area_id)
	return self._area_map[area_id] or -1
end

function AreaMgr:remove_by_server_id(server_id)
	for area_id, s in pairs(self._area_map) do
		if s == server_id then
			self._area_map[area_id] = nil
		end
	end
end

return AreaMgr
