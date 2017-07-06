
-- TODO should create by xls or csv
-- if default is '_Null' means no default value

DataStructDef = {}

DataStructDef.role_info = 
{
	role_id = { type=_Int64, save=1, default='_Null'},
	role_name = { type=_String, save=1, default='_Null'},
	lv = { type=_Int, save=1, default='1'},
	exp = { type=_Int, save=1, default='0'},
	scene_id = { type=_Int, save=1, default='0'},
	pos_x = { type=_Int, save=1, default='0'},
	pos_y = { type=_Int, save=1, default='0'},
	cur_hp = { type=_Int, save=0, default='0'},
}

return DataStructDef
