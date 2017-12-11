
ServerConfig = class()

function ServerConfig:ctor(server_id, server_type)
	self._server_id = server_id
	self._server_type = server_type
	self._all_scene_list = {}
	self._single_scene_list = {}
	self._from_to_scene_list = {}
	self._area_list = {}
	self._no_broadcast = false
	self._ip = ""
	self._port = 0
	self._db_name_map = {} -- {[db_type]=db_name}
end

function ServerConfig:add_single_scene(scene_id)
	if self._all_scene_list[scene_id] then
		Log.warn("ServerConfig:add_single_scene duplicate scene_id=%d", scene_id)
		return
	end
	table.insert(self._single_scene_list, scene_id)
	self._all_scene_list[scene_id] = scene_id
end

function ServerConfig:add_from_to_scene(from, to)
	if self._all_scene_list[from] or self._all_scene_list[to] then
		Log.warn("ServerConfig:add_from_to_scene duplicate from=%d to=%d", from, to)
		return
	end
	table.insert(self._from_to_scene_list, from)
	table.insert(self._from_to_scene_list, to)
	for v=from, to do
		self._all_scene_list[v] = v
	end
end

function ServerConfig:add_area(area_id)
	for _, v in ipairs(self._area_list) do
		if v == area_id then
			Log.warn("ServerConfig:add_area duplicate area_id=%d", area_id)
			return
		end
	end
	table.insert(self._area_list, area_id)
end

return ServerConfig
