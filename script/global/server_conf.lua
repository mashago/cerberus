
ServerConfig = {}
ServerConfig._server_id = 0
ServerConfig._server_type = ServerType.NULL
ServerConfig._all_scene_id = {}
ServerConfig._single_scene_id = {}
ServerConfig._from_to_scene_id = {}

function ServerConfig.add_single_scene_id(scene_id)
	if ServerConfig._all_scene_id[scene_id] then
		Log.warn("ServerConfig.add_single_scene_id duplicate scene_id=%d", scene_id)
		return
	end
	table.insert(ServerConfig._single_scene_id, scene_id)
	ServerConfig._all_scene_id[scene_id] = scene_id
end

function ServerConfig.add_from_to_scene_id(from, to)
	if ServerConfig._all_scene_id[from] or ServerConfig._all_scene_id[to] then
		Log.warn("ServerConfig.add_single_scene_id duplicate from=%d to=%d", from, to)
		return
	end
	table.insert(ServerConfig._from_to_scene_id, from)
	table.insert(ServerConfig._from_to_scene_id, to)
	for v=from, to do
		ServerConfig._all_scene_id[v] = v
	end
end

return ServerConfig
