
-- data define
_Null 			= 0
_Byte 			= 1
_Bool 			= 2
_Int 			= 3
_Float 			= 4
_Short 			= 5
_Int64 			= 6
_String			= 7
_Struct 		= 8
_StructString 	= 9 -- only for network transfer

_ByteArray 		= 11
_BoolArray		= 12
_IntArray		= 13
_FloatArray		= 14
_ShortArray 	= 15
_Int64Array 	= 16
_StringArray 	= 17
_StructArray 	= 18

ServerType =
{
	NULL 			= 0,
	LOGIN 			= 1,
	DB 				= 2,

	MASTER			= 3,
	BRIDGE 			= 4,
	GATE 			= 5,
	SCENE 			= 6,

	PUBLIC 			= 8,
}

ServerTypeName = { }
for k, v in pairs(ServerType) do
	ServerTypeName[v] = k
end

MAILBOX_ID_NIL = 0

