
-- NOTE:
-- 1. should set by coder handly
-- 2. field position will be random, you have to accept this
-- 3. if default is '_Null' means no default value
-- 4. if key=1, will set a index for the field

DataStructDef = {}

DataStructDef.role_info = 
{
	[1] = {id=1, field='role_id', type=_Int64, save=1, default='_Null', key=1},
	[2] = {id=2, field='role_name', type=_String, save=1, default='_Null'},
	[3] = {id=3, field='user_id', type=_Int64, save=1, default='_Null', key=0},
	[4] = {id=4, field='channel_id', type=_Int, save=1, default='_Null'},
	[5] = {id=5, field='area_id', type=_Int, save=1, default='_Null'},
	[6] = {id=6, field='is_delete', type=_Bool, save=1, default='0'},
	[7] = {id=7, field='lv', type=_Int, save=1, default='1'},
	[8] = {id=8, field='exp', type=_Int, save=1, default='0'},
	[9] = {id=9, field='scene_id', type=_Int, save=1, default='1'},
	[10] = {id=10, field='pos_x', type=_Int, save=1, default='0'},
	[11] = {id=11, field='pos_y', type=_Int, save=1, default='0'},
	[12] = {id=12, field='cur_hp', type=_Int, save=0, default='0'},
}

function DataStructDef.init_cfg(table_name)
	local table_cfg = DataStructDef[table_name]
	if not table_cfg then
		return
	end

	for k, field_cfg in ipairs(table_cfg) do
		table_cfg[field_cfg.field] = field_cfg
	end
end

DataStructDef.init_cfg("role_info")

function DataStructDef.convert_type_str2mem(table_name, field_name, value)
	local table_cfg = DataStructDef[table_name]
	if not table_cfg then
		return nil
	end

	local field_cfg = table_cfg[field_name]
	if not field_cfg then
		return nil
	end

	local field_type = field_cfg.type
	-- type cast
	if field_type == _String then
		return value
	end

	if field_type == _Bool then
		return value == "1"
	end

	if field_type == _Byte or field_type == _Int
	or field_type == _Float or field_type == _Short
	or field_type == _Int64 then
		return tonumber(value)
	end

	if field_type == _Struct then
		return Util.unserialize(value)
	end

	Log.warn("DataStructDef.convert_type_str2mem unknow type table_name=%s field_name=%s field_type=%d", field_type)
	return nil

end

return DataStructDef
