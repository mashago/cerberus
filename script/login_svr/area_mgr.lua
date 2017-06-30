
AreaMgr = {}

AreaMgr._area_map = {} -- {[area_id]=[server_id], ...}

function AreaMgr.register_area(server_id, area_list)
	for _, area_id in ipairs(area_list) do
		if AreaMgr._area_map[area_id] then
			-- multi server register same area
			return false
		end
	end

	for _, area_id in ipairs(area_list) do
		AreaMgr._area_map[area_id] = server_id
	end
	return true
end

return AreaMgr
