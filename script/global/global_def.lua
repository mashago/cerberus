
ServerType =
{
	NULL 			= 0,
	ROUTER 			= 1,
	SCENE 			= 2,
	DB 				= 3,
	BRIDGE 			= 4,
	LOGIN 			= 5,
	PUBLIC 			= 6,
	CROSS 			= 7,
	PAY 			= 8,
	CHAT 			= 9,
}

ConnType =
{
	NULL 	= 0,
	UNTRUST = 1,
	TRUST 	= 2,
}

ServerErrorCode =
{
	SUCCESS = 1,
	REGISTER_FAIL = 2,
	REGISTER_UNTRUST = 3,
	RPC_FAIL = 4,
}

ErrorCode =
{
	SUCCESS = 1,
	SYS_ERROR = 2,
	USER_LOGIN_FAIL = 3,
	USER_LOGIN_PASSWORD_MISMATCH = 4,
	CREATE_ROLE_FAIL = 5,
}

