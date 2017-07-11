
-- NOTE:
-- 1. should set by coder handly
-- 2. field position will be random, you have to accept this
-- 3. if default is '_Null' means no default value
-- 4. if key=1, will set a index for the field

DataStructDef = {}

DataStructDef.game_db = {}
DataStructDef.game_db.role_info = 
{
	role_id = { type=_Int64, save=1, default='_Null', key=1},
	role_name = { type=_String, save=1, default='_Null'},
	user_id = { type=_Int64, save=1, default='_Null', key=0},
	channel_id = { type=_Int, save=1, default='_Null'},
	area_id = { type=_Int, save=1, default='_Null'},
	is_delete = { type=_Int, save=1, default='0'},
	lv = { type=_Int, save=1, default='1'},
	exp = { type=_Int, save=1, default='0'},
	scene_id = { type=_Int, save=1, default='1'},
	pos_x = { type=_Int, save=1, default='0'},
	pos_y = { type=_Int, save=1, default='0'},
	cur_hp = { type=_Int, save=0, default='0'},
}

return DataStructDef
