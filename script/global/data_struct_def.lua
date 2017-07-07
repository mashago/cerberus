
-- TODO should create by xls or csv
-- if default is '_Null' means no default value

DataStructDef = {}

DataStructDef.login_db = {}
DataStructDef.login_db.user_info = 
{
	user_id = { type=_Int64, save=1, default='_Null', key='PRI', ai=1000},
	channel_id = { type=_Int, save=1, default='0', key='MUL'},
	username = { type=_String, save=1, default='_Null', key='UNI'},
	password = { type=_String, save=1, default='_Null'},
	create_date = { type=_Int64, save=1, default='0'},
}

DataStructDef.login_db.user_role = 
{
	role_id = { type=_Int64, save=1, default='_Null', key='PRI', ai=10000},
	user_id = { type=_Int64, save=1, default='_Null', key='MUL'},
	area_id = { type=_Int, save=1, default='_Null', key='MUL'},
	role_name = { type=_String, save=1, default='_Null', key='UNI'},
}


DataStructDef.game_db = {}
DataStructDef.game_db.role_info = 
{
	role_id = { type=_Int64, save=1, default='_Null'},
	role_name = { type=_String, save=1, default='_Null'},
	user_id = { type=_Int64, save=1, default='_Null'},
	channel_id = { type=_Int, save=1, default='_Null'},
	area_id = { type=_Int, save=1, default='_Null'},
	lv = { type=_Int, save=1, default='1'},
	exp = { type=_Int, save=1, default='0'},
	scene_id = { type=_Int, save=1, default='1'},
	pos_x = { type=_Int, save=1, default='0'},
	pos_y = { type=_Int, save=1, default='0'},
	cur_hp = { type=_Int, save=0, default='0'},
}

return DataStructDef
