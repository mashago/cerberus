
-- NOTE:
-- 1. should set by coder handly
-- 2. field position will be random, you have to accept this
-- 3. if default is '_Null' means no default value
-- 4. if key=1, will set a index for the field

DataStructDef = {}

DataStructDef.role_info = 
{
	[1] = {field='role_id', type=_Int64, save=1, default='_Null', key=1},
	[2] = {field='role_name', type=_String, save=1, default='_Null'},
	[3] = {field='user_id', type=_Int64, save=1, default='_Null', key=0},
	[4] = {field='channel_id', type=_Int, save=1, default='_Null'},
	[5] = {field='area_id', type=_Int, save=1, default='_Null'},
	[6] = {field='is_delete', type=_Int, save=1, default='0'},
	[7] = {field='lv', type=_Int, save=1, default='1'},
	[8] = {field='exp', type=_Int, save=1, default='0'},
	[9] = {field='scene_id', type=_Int, save=1, default='1'},
	[10] = {field='pos_x', type=_Int, save=1, default='0'},
	[11] = {field='pos_y', type=_Int, save=1, default='0'},
	[12] = {field='cur_hp', type=_Int, save=0, default='0'},
}

return DataStructDef
