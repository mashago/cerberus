
MID = {}
MID._id_name_map = 
{
	-- msg for test
	[1] = "c2s_client_test_req",
	[2] = "s2c_client_test_ret",
	[3] = "c2s_rpc_test_req",
	[4] = "s2c_rpc_test_ret",
	[5] = "c2s_rpc_send_test_req",
	[6] = "c2s_rpc_mix_test_req",

	-- login server handle
	[10005] = "c2s_user_login_req",
	[10006] = "s2c_user_login_ret",
	[10007] = "c2s_area_list_req",
	[10008] = "s2c_area_list_ret",
	[10009] = "c2s_role_list_req",
	[10010] = "s2c_role_list_ret",
	[10011] = "c2s_create_role_req",
	[10012] = "s2c_create_role_ret",
	[10013] = "c2s_delete_role_req",
	[10014] = "s2c_delete_role_ret",
	[10015] = "c2s_select_role_req",
	[10016] = "s2c_select_role_ret",
	[10017] = "s2c_user_kick",

	-- gate server handle
	[20001] = "s2c_role_kick",
	[20021] = "c2s_role_enter_req",
	[20022] = "s2c_role_enter_ret",
	[20023] = "s2c_role_attr_ret",
	[20024] = "c2s_role_attr_change_req",
	[20025] = "s2c_role_attr_change_ret",

	[20026] = "s2c_attr_info_ret",
	[20027] = "s2c_attr_insert_ret",
	[20028] = "s2c_attr_delete_ret",
	[20029] = "s2c_attr_modify_ret",

	-- msg for server
	-- about master_svr
	
	[60001] = "s2s_shake_hand_req", -- after connect to success, send this
	[60002] = "s2s_shake_hand_ret",
	[60003] = "s2s_shake_hand_invite",
	[60004] = "s2s_shake_hand_cancel",

	[60011] = "s2s_rpc_req",
	[60012] = "s2s_rpc_send_req",
	[60013] = "s2s_rpc_ret",

	[60021] = "s2s_register_area_req",
	[60022] = "s2s_register_area_ret",

	[60031] = "s2s_gate_role_enter_req",
	[60032] = "s2s_gate_role_enter_ret",
	[60033] = "s2s_gate_role_disconnect",

}

local function create_msg_id_array()
	for k, v in pairs(MID._id_name_map) do
		MID[v] = k
	end
end
create_msg_id_array()

local TestStruct = 
{
	{ "byte", _Byte },
	{ "bool", _Bool },
	{ "int", _Int },
	{ "float", _Float },
	{ "short", _Short },
	{ "int64", _Int64 },
	{ "string", _String },
}

local AreaListStruct = 
{
	{ "area_id", _Int },
	{ "area_name", _String },
}


local AreaRoleStruct = 
{
	{ "role_id", _Int64 },
	{ "role_name", _String },
}

local AreaRoleListStruct = 
{
	{ "area_id", _Int },
	{ "role_list", _StructArray, AreaRoleStruct },
}

local PeerAddrStruct =
{
	{ "ip", _String },
	{ "port", _Int },
}

-----------------------------------

local ByteAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Byte },
}

local BoolAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Bool },
}

local IntAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Int },
}

local FloatAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Float },
}

local ShortAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Short },
}

local Int64AttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Int64 },
}

local StringAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _String },
}

local StructAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _StructString },
}

local AttrTableStruct =
{
	{ "byte_attr_list", _StructArray, ByteAttrStruct },
	{ "bool_attr_list", _StructArray, BoolAttrStruct },
	{ "int_attr_list", _StructArray, IntAttrStruct },
	{ "float_attr_list", _StructArray, FloatAttrStruct },
	{ "short_attr_list", _StructArray, ShortAttrStruct },
	{ "int64_attr_list", _StructArray, Int64AttrStruct },
	{ "string_attr_list", _StructArray, StringAttrStruct },
	{ "struct_attr_list", _StructArray, StructAttrStruct },
}

local ModifyAttrTableStruct =
{
	{ "keys", _Struct, AttrTableStruct },
	{ "attrs", _Struct, AttrTableStruct },
}

-----------------------------------

MSG_DEF_MAP = {}
MSG_DEF_MAP._def_map =
{
	c2s_client_test_req =
	{
		{ "byte", _Byte },
		{ "bool", _Bool },
		{ "int", _Int },
		{ "float", _Float },
		{ "short", _Short },
		{ "int64", _Int64 },
		{ "string", _String },
		{ "struct", _Struct, TestStruct },

		{ "bytearray", _ByteArray },
		{ "boolarray", _BoolArray },
		{ "intarray", _IntArray },
		{ "floatarray", _FloatArray },
		{ "shortarray", _ShortArray },
		{ "int64array", _Int64Array },
		{ "stringarray", _StringArray },
		{ "structarray", _StructArray, TestStruct },
	},

	s2c_client_test_ret =
	{
		{ "byte", _Byte },
		{ "bool", _Bool },
		{ "int", _Int },
		{ "float", _Float },
		{ "short", _Short },
		{ "int64", _Int64 },
		{ "string", _String },
		{ "struct", _Struct, TestStruct },

		{ "bytearray", _ByteArray },
		{ "boolarray", _BoolArray },
		{ "intarray", _IntArray },
		{ "floatarray", _FloatArray },
		{ "shortarray", _ShortArray },
		{ "int64array", _Int64Array },
		{ "stringarray", _StringArray },
		{ "structarray", _StructArray, TestStruct },
	},

	c2s_rpc_test_req =
	{
		{ "buff", _String },
	},
	s2c_rpc_test_ret =
	{
		{ "result", _Int },
		{ "buff", _String },
		{ "sum", _Int },
	},
	c2s_rpc_send_test_req =
	{
		{ "buff", _String },
	},
	c2s_rpc_mix_test_req =
	{
		{ "buff", _String },
	},

	-----------------------------------------------------------

	c2s_user_login_req =
	{
		{ "username", _String },
		{ "password", _String },
		{ "channel_id", _Int },
	},
	s2c_user_login_ret =
	{
		{ "result", _Int },
	},

	c2s_area_list_req =
	{
	},
	s2c_area_list_ret =
	{
		{ "area_list", _StructArray, AreaListStruct },
	},

	c2s_role_list_req =
	{
	},
	s2c_role_list_ret =
	{
		{ "result", _Int },
		{ "area_role_list", _StructArray, AreaRoleListStruct },
	},

	c2s_create_role_req =
	{
		{ "area_id", _Int },
		{ "role_name", _String },
	},
	s2c_create_role_ret =
	{
		{ "result", _Int },
		{ "role_id", _Int64 },
	},

	c2s_delete_role_req =
	{
		{ "area_id", _Int },
		{ "role_id", _Int64 },
	},
	s2c_delete_role_ret =
	{
		{ "result", _Int },
		{ "role_id", _Int64 },
	},

	c2s_select_role_req =
	{
		{ "area_id", _Int },
		{ "role_id", _Int64 },
	},
	s2c_select_role_ret =
	{
		{ "result", _Int },
		{ "ip", _String },
		{ "port", _Int },
		{ "user_id", _Int64 },
		{ "token", _String },
	},

	s2c_user_kick =
	{
		{ "reason", _Int },
	},

	----------------------------------------
	s2c_role_kick =
	{
		{ "reason", _Int },
	},

	c2s_role_enter_req =
	{
		{ "user_id", _Int64 },
		{ "token", _String },
	},
	s2c_role_enter_ret =
	{
		{ "result", _Int },
	},

	s2c_role_attr_ret =
	{
		{ "role_id", _Int64 },
		{ "attr_table", _Struct, AttrTableStruct },
	},

	c2s_role_attr_change_req =
	{
		{ "attr_table", _Struct, AttrTableStruct },
	},

	s2c_role_attr_change_ret =
	{
		{ "role_id", _Int64 },
		{ "attr_table", _Struct, AttrTableStruct },
	},

	s2c_attr_info_ret =
	{
		{ "sheet_name", _String },
		{ "rows", _StructArray, AttrTableStruct },
	},

	s2c_attr_insert_ret =
	{
		{ "sheet_name", _String },
		{ "rows", _StructArray, AttrTableStruct },
	},

	s2c_attr_delete_ret =
	{
		{ "sheet_name", _String },
		{ "rows", _StructArray, AttrTableStruct },
	},

	s2c_attr_modify_ret =
	{
		{ "sheet_name", _String },
		{ "rows", _StructArray, ModifyAttrTableStruct },
	},

	----------------------------------------

	s2s_shake_hand_req =
	{
		{ "server_id", _Int },
		{ "server_type", _Int },
		{ "single_scene_list", _IntArray },
		{ "from_to_scene_list", _IntArray },
		{ "ip", _String },
		{ "port", _Int },
	},

	s2s_shake_hand_ret =
	{
		{ "result", _Int },
		{ "server_id", _Int },
		{ "server_type", _Int },
		{ "single_scene_list", _IntArray },
		{ "from_to_scene_list", _IntArray },
	},

	s2s_shake_hand_invite =
	{
		{ "peer_list", _StructArray, PeerAddrStruct },
	},

	s2s_shake_hand_cancel =
	{
		{ "server_id", _Int },
		{ "ip", _String },
		{ "port", _Int },
	},


	s2s_rpc_req =
	{
		{ "from_server_id", _Int },
		{ "to_server_id", _Int },
		{ "session_id", _Int64 },
		{ "func_name", _String },
		{ "param", _String },
	},

	s2s_rpc_send_req =
	{
		{ "from_server_id", _Int },
		{ "to_server_id", _Int },
		{ "session_id", _Int64 },
		{ "func_name", _String },
		{ "param", _String },
	},

	s2s_rpc_ret =
	{
		{ "result", _Bool },
		{ "from_server_id", _Int },
		{ "to_server_id", _Int },
		{ "session_id", _Int64 },
		{ "param", _String },
	},

	s2s_register_area_req =
	{
		{ "area_list", _IntArray },
	},

	s2s_register_area_ret =
	{
		{ "result", _Int },
	},

	s2s_gate_role_enter_req =
	{
		{ "role_id", _Int64 },
		{ "scene_id", _Int },
	},
	s2s_gate_role_enter_ret =
	{
		{ "result", _Int },
		{ "role_id", _Int64 },
	},

	s2s_gate_role_disconnect =
	{
	},

}

local function create_msg_def_array()
	for k, v in pairs(MSG_DEF_MAP._def_map) do
		MSG_DEF_MAP[MID[k]] = v
	end
end
create_msg_def_array()

-- do msg handler function directly
RAW_MID = 
{
	[MID.c2s_client_test_req] = true,
	[MID.c2s_rpc_test_req] = true,
	[MID.c2s_rpc_send_test_req] = true,
	[MID.c2s_rpc_mix_test_req] = true,

	[MID.s2s_shake_hand_req] = true,
	[MID.s2s_shake_hand_ret] = true,
	[MID.s2s_shake_hand_invite] = true,
	[MID.s2s_shake_hand_cancel] = true,

	[MID.c2s_user_login_req] = true,
	[MID.c2s_role_enter_req] = true,

	[MID.s2s_rpc_req] = true,
	[MID.s2s_rpc_send_req] = true,
	[MID.s2s_rpc_ret] = true,
	[MID.s2s_register_area_req] = true,
	[MID.s2s_register_area_ret] = true,

	[MID.s2s_gate_role_enter_req] = true,
	[MID.s2s_gate_role_enter_ret] = true,
}

--[[
-- handle these msg which only from trust mailbox
TRUST_MID =
{
	[MID.s2s_rpc_req] = true,
	[MID.s2s_rpc_ret] = true,
	[MID.s2s_register_area_req] = true,
	[MID.s2s_register_area_ret] = true,
}
--]]

