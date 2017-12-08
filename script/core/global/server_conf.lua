
ServerConfig = {}
ServerConfig._server_id = 0
ServerConfig._server_type = ServerType.NULL
ServerConfig._all_scene_list = {}
ServerConfig._single_scene_list = {}
ServerConfig._from_to_scene_list = {}
ServerConfig._area_list = {}
ServerConfig._no_broadcast = false
ServerConfig._ip = ""
ServerConfig._port = 0
ServerConfig._db_name_map = {} -- {[db_type]=db_name}

function ServerConfig.add_single_scene(scene_id)
	if ServerConfig._all_scene_list[scene_id] then
		Log.warn("ServerConfig.add_single_scene duplicate scene_id=%d", scene_id)
		return
	end
	table.insert(ServerConfig._single_scene_list, scene_id)
	ServerConfig._all_scene_list[scene_id] = scene_id
end

function ServerConfig.add_from_to_scene(from, to)
	if ServerConfig._all_scene_list[from] or ServerConfig._all_scene_list[to] then
		Log.warn("ServerConfig.add_from_to_scene duplicate from=%d to=%d", from, to)
		return
	end
	table.insert(ServerConfig._from_to_scene_list, from)
	table.insert(ServerConfig._from_to_scene_list, to)
	for v=from, to do
		ServerConfig._all_scene_list[v] = v
	end
end

function ServerConfig.add_area(area_id)
	for _, v in ipairs(ServerConfig._area_list) do
		if v == area_id then
			Log.warn("ServerConfig.add_area duplicate area_id=%d", area_id)
			return
		end
	end
	table.insert(ServerConfig._area_list, area_id)
end

return ServerConfig
