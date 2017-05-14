
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "pluto.h"
#include "luanetworkreg.h"
#include "luanetwork.h"

int luanetwork_instance(lua_State *L)
{
	LuaNetwork **ptr = (LuaNetwork**)lua_newuserdata(L, sizeof(LuaNetwork **));
	*ptr = LuaNetwork::Instance();

	luaL_getmetatable(L, "LuaNetwork");

	lua_setmetatable(L, -2);

	return 1;
}

//////////////////////////////////////////////////////

int luanetwork_write_msg_id(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TNUMBER);

	(*s)->WriteMsgId(lua_tointeger(L, -1));

	return 0;
}

int luanetwork_write_byte(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TNUMBER);

	bool ret = (*s)->WriteByte((char)lua_tointeger(L, -1));
	lua_pushboolean(L, ret);

	return 1;
}

int luanetwork_write_int(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TNUMBER);

	bool ret = (*s)->WriteInt((int)lua_tointeger(L, -1));
	lua_pushboolean(L, ret);

	return 1;
}

int luanetwork_write_float(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TNUMBER);

	bool ret = (*s)->WriteFloat((float)lua_tonumber(L, -1));
	lua_pushboolean(L, ret);

	return 1;
}

int luanetwork_write_bool(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TBOOLEAN);

	bool ret = (*s)->WriteBool(lua_toboolean(L, -1) != 0);
	lua_pushboolean(L, ret);

	return 1;
}

int luanetwork_write_short(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TNUMBER);

	bool ret = (*s)->WriteShort((short)lua_tointeger(L, -1));
	lua_pushboolean(L, ret);

	return 1;
}

int luanetwork_write_int64(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TNUMBER);

	bool ret = (*s)->WriteInt64(lua_tointeger(L, -1));
	lua_pushboolean(L, ret);

	return 1;
}


int luanetwork_write_string(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TSTRING);

	bool ret = (*s)->WriteString((int)luaL_len(L,-1), lua_tostring(L, -1));
	lua_pushboolean(L, ret);

	return 1;
}


#define write_table_len(count) \
do { \
count = (unsigned short)luaL_len(L, -1); \
bool ret = (*s)->WriteShort(count); \
if (!ret) \
{ \
	lua_pushboolean(L, ret); \
	return 1; \
} \
} while (false)

int luanetwork_write_byte_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TTABLE);

	//得到table长度
	unsigned short count = 0;
	write_table_len(count);

	for (unsigned short i = 1; i <= count; ++i)
	{
		lua_pushinteger(L,i);
		lua_rawget(L, -2);
		bool ret = (*s)->WriteByte((char)lua_tointeger(L, -1));
		if (!ret)
		{
			lua_pushboolean(L, ret);
			return 1;
		}
		lua_pop(L, 1);
	}
	
	lua_pushboolean(L, true);
	return 1;
}

int luanetwork_write_int_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TTABLE);

	//得到table长度
	unsigned short count = 0;
	write_table_len(count);

	for (unsigned short i = 1; i <= count; ++i)
	{
		lua_pushinteger(L, i);
		lua_rawget(L, -2);
		bool ret = (*s)->WriteInt((int)lua_tointeger(L, -1));
		if (!ret)
		{
			lua_pushboolean(L, ret);
			return 1;
		}
		lua_pop(L, 1);
	}

	lua_pushboolean(L, true);
	return 1;
}

int luanetwork_write_float_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TTABLE);

	//得到table长度
	unsigned short count = 0;
	write_table_len(count);

	for (unsigned short i = 1; i <= count; ++i){
		lua_pushinteger(L, i);
		lua_rawget(L, -2);
		bool ret = (*s)->WriteFloat((float)lua_tonumber(L,-1));
		if (!ret)
		{
			lua_pushboolean(L, ret);
			return 1;
		}
		lua_pop(L, 1);
	}

	lua_pushboolean(L, true);
	return 1;
}

int luanetwork_write_bool_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TTABLE);

	//得到table长度
	unsigned short count = 0;
	write_table_len(count);

	for (unsigned short i = 1; i <= count; ++i){
		lua_pushinteger(L, i);
		lua_rawget(L, -2);
		bool ret = (*s)->WriteBool(lua_toboolean(L, -1) != 0);
		if (!ret)
		{
			lua_pushboolean(L, ret);
			return 1;
		}
		lua_pop(L, 1);
	}

	lua_pushboolean(L, true);
	return 1;
}

int luanetwork_write_short_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TTABLE);

	//得到table长度
	unsigned short count = 0;
	write_table_len(count);

	for (unsigned short i = 1; i <= count; ++i){
		lua_pushinteger(L, i);
		lua_rawget(L, -2);
		bool ret = (*s)->WriteShort((short)lua_tointeger(L, -1));
		if (!ret)
		{
			lua_pushboolean(L, ret);
			return 1;
		}
		lua_pop(L, 1);
	}

	lua_pushboolean(L, true);
	return 1;
}

int luanetwork_write_int64_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TTABLE);

	//得到table长度
	unsigned short count = 0;
	write_table_len(count);

	for (unsigned short i = 1; i <= count; ++i){
		lua_pushinteger(L, i);
		lua_rawget(L, -2);
		bool ret = (*s)->WriteInt64(lua_tointeger(L, -1));
		if (!ret)
		{
			lua_pushboolean(L, ret);
			return 1;
		}
		lua_pop(L, 1);
	}

	lua_pushboolean(L, true);
	return 1;
}

int luanetwork_write_string_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TTABLE);

	//得到table长度
	unsigned short count = 0;
	write_table_len(count);

	for (unsigned short i = 1; i <= count; ++i){
		lua_pushinteger(L, i);
		lua_rawget(L, -2);
		bool ret = (*s)->WriteString((int)luaL_len(L, -1), lua_tostring(L, -1));
		if (!ret)
		{
			lua_pushboolean(L, ret);
			return 1;
		}
		lua_pop(L, 1);
	}

	lua_pushboolean(L, true);
	return 1;
}

int luanetwork_send(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TNUMBER);

	bool ret = (*s)->Send((unsigned)lua_tointeger(L,-1));

	lua_pushboolean(L, ret);

	return 1;
}

//////////////////////////////////////////////////////

int luanetwork_read_byte(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	char out_val = 0;
	bool ret = (*s)->ReadByte(out_val);

	lua_pushboolean(L, ret);
	lua_pushinteger(L, out_val);

	return 2;
}

int luanetwork_read_int(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	int out_val = 0;
	bool ret = (*s)->ReadInt(out_val);

	lua_pushboolean(L, ret);
	lua_pushinteger(L, out_val);

	return 2;
}

int luanetwork_read_float(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	float out_val = 0;
	bool ret = (*s)->ReadFloat(out_val);

	lua_pushboolean(L, ret);
	lua_pushnumber(L, out_val);

	return 2;
}

int luanetwork_read_bool(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	bool out_val = false;
	bool ret = (*s)->ReadBool(out_val);

	lua_pushboolean(L, ret);
	lua_pushboolean(L, out_val);

	return 2;
}

int luanetwork_read_int64(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	long long out_val = 0;
	bool ret = (*s)->ReadInt64(out_val);

	lua_pushboolean(L, ret);
	lua_pushinteger(L, out_val);

	return 2;
}

int luanetwork_read_short(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	short out_val = 0;
	bool ret = (*s)->ReadShort(out_val);

	lua_pushboolean(L, ret);
	lua_pushinteger(L, out_val);

	return 2;
}

int luanetwork_read_string(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	int out_len = 0;
	char out_val[MSGLEN_MAX+1] = {};
	bool ret = (*s)->ReadString(out_len, out_val);

	lua_pushboolean(L, ret);
	lua_pushstring(L, out_val);

	return 2;
}

int luanetwork_read_byte_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	short count = 0;
	bool ret = (*s)->ReadShort(count);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);

	for (unsigned short i = 1; i <= (unsigned short)count; ++i){
		char out_val = 0;
		bool ret = (*s)->ReadByte(out_val);
		if (!ret)
		{
			lua_pushboolean(L, ret);
			lua_insert(L, -2);
			return 2;
		}

		lua_pushinteger(L, i);
		lua_pushinteger(L,out_val);
		lua_rawset(L, -3);
	}

	lua_pushboolean(L, ret);
	lua_insert(L, -2);

	return 2;
}

int luanetwork_read_int_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	short count = 0;
	bool ret = (*s)->ReadShort(count);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);

	for (unsigned short i = 1; i <= (unsigned short)count; ++i){
		int out_val = 0;
		bool ret = (*s)->ReadInt(out_val);
		if (!ret)
		{
			lua_pushboolean(L, ret);
			lua_insert(L, -2);
			return 2;
		}

		lua_pushinteger(L, i);
		lua_pushinteger(L, out_val);
		lua_rawset(L, -3);
	}

	lua_pushboolean(L, ret);
	lua_insert(L, -2);

	return 2;
}

int luanetwork_read_float_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	short count = 0;
	bool ret = (*s)->ReadShort(count);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);

	for (unsigned short i = 1; i <= (unsigned short)count; ++i){
		float out_val = 0;
		bool ret = (*s)->ReadFloat(out_val);
		if (!ret)
		{
			lua_pushboolean(L, ret);
			lua_insert(L, -2);
			return 2;
		}

		lua_pushinteger(L, i);
		lua_pushnumber(L, out_val);
		lua_rawset(L, -3);
	}

	lua_pushboolean(L, ret);
	lua_insert(L, -2);

	return 2;
}

int luanetwork_read_bool_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	short count = 0;
	bool ret = (*s)->ReadShort(count);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);

	for (unsigned short i = 1; i <= (unsigned short)count; ++i){
		bool out_val = 0;
		bool ret = (*s)->ReadBool(out_val);
		if (!ret)
		{
			lua_pushboolean(L, ret);
			lua_insert(L, -2);
			return 2;
		}

		lua_pushinteger(L, i);
		lua_pushboolean(L, out_val);
		lua_rawset(L, -3);
	}

	lua_pushboolean(L, ret);
	lua_insert(L, -2);

	return 2;
}

int luanetwork_read_int64_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	short count = 0;
	bool ret = (*s)->ReadShort(count);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);

	for (unsigned short i = 1; i <= (unsigned short)count; ++i){
		long long out_val = 0;
		bool ret = (*s)->ReadInt64(out_val);
		if (!ret)
		{
			lua_pushboolean(L, ret);
			lua_insert(L, -2);
			return 2;
		}

		lua_pushinteger(L, i);
		lua_pushinteger(L, out_val);
		lua_rawset(L, -3);
	}

	lua_pushboolean(L, ret);
	lua_insert(L, -2);

	return 2;
}

int luanetwork_read_short_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	short count = 0;
	bool ret = (*s)->ReadShort(count);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);

	for (unsigned short i = 1; i <= (unsigned short)count; ++i){
		short out_val = 0;
		bool ret = (*s)->ReadShort(out_val);
		if (!ret)
		{
			lua_pushboolean(L, ret);
			lua_insert(L, -2);
			return 2;
		}

		lua_pushinteger(L, i);
		lua_pushinteger(L, out_val);
		lua_rawset(L, -3);
	}

	lua_pushboolean(L, ret);
	lua_insert(L, -2);

	return 2;
}

int luanetwork_read_string_array(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	short count = 0;
	bool ret = (*s)->ReadShort(count);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);

	for (unsigned short i = 1; i <= (unsigned short)count; ++i){
		int out_len = 0;
		char out_val[MSGLEN_MAX+1] = {};
		bool ret = (*s)->ReadString(out_len, out_val);
		if (!ret)
		{
			lua_pushboolean(L, ret);
			lua_insert(L, -2);
			return 2;
		}

		lua_pushinteger(L, i);
		lua_pushstring(L, out_val);
		lua_rawset(L, -3);
	}

	lua_pushboolean(L, ret);
	lua_insert(L, -2);

	return 2;
}

int luanetwork_get_recv_msg_id(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	int msg_id = (*s)->ReadMsgId();
	lua_pushinteger(L, msg_id);

	return 1;
}

/*
int luanetwork_connect_to(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TNUMBER);
	luaL_checktype(L, -2, LUA_TSTRING);

	int port = (int)lua_tointeger(L, -1);
	const char* ip = lua_tostring(L, -2);

	unsigned out_session_id = INT_MAX;
	bool ret = (*s)->connect_to(ip, port, out_session_id);

	lua_pushboolean(L, ret);
	lua_pushinteger(L, out_session_id);

	return 2;
}
*/

/*
int luanetwork_close_socket(lua_State* L)
{
	LuaNetwork** s = (LuaNetwork**)luaL_checkudata(L, 1, "LuaNetwork");
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TNUMBER);

	unsigned session_id = (unsigned)lua_tointeger(L, -1);

	(*s)->close_socket(session_id);

	return 0;
}
*/

//////////////////////////////////////////////////////



// define constructor
static const luaL_Reg lua_reg_construct_funcs[] =
{
	{ "instance", luanetwork_instance },
	{ NULL, NULL},
};

// define member functions
static const luaL_Reg lua_reg_member_funcs[] = 
{
	{ "write_msg_id", luanetwork_write_msg_id },
	{ "write_byte", luanetwork_write_byte },
	{ "write_int", luanetwork_write_int },
	{ "write_float", luanetwork_write_float },
	{ "write_bool", luanetwork_write_bool },
	{ "write_short", luanetwork_write_short },
	{ "write_int64", luanetwork_write_int64 },
	{ "write_string", luanetwork_write_string },

	{ "write_byte_array", luanetwork_write_byte_array },
	{ "write_int_array", luanetwork_write_int_array },
	{ "write_float_array", luanetwork_write_float_array },
	{ "write_bool_array", luanetwork_write_bool_array },
	{ "write_short_array", luanetwork_write_short_array },
	{ "write_int64_array", luanetwork_write_int64_array },
	{ "write_string_array", luanetwork_write_string_array },

	{ "send", luanetwork_send },

	{ "read_byte", luanetwork_read_byte },
	{ "read_int", luanetwork_read_int },
	{ "read_float", luanetwork_read_float },
	{ "read_bool", luanetwork_read_bool },
	{ "read_int64", luanetwork_read_int64 },
	{ "read_short", luanetwork_read_short },
	{ "read_string", luanetwork_read_string },

	{ "read_byte_array", luanetwork_read_byte_array },
	{ "read_int_array", luanetwork_read_int_array },
	{ "read_float_array", luanetwork_read_float_array },
	{ "read_bool_array", luanetwork_read_bool_array },
	{ "read_int64_array", luanetwork_read_int64_array },
	{ "read_short_array", luanetwork_read_short_array },
	{ "read_string_array", luanetwork_read_string_array },

	{ "get_recv_msg_id", luanetwork_get_recv_msg_id },
	// { "get_recv_addition", luanetwork_get_recv_addition },
	// { "is_read_all", luanetwork_is_read_all },

	// { "connect_to", luanetwork_connect_to },

	// { "close_socket", luanetwork_close_socket},

	{ NULL, NULL },
};

int luaopen_luanetwork(lua_State *L)
{
	luaL_newmetatable(L, "LuaNetwork");

	lua_pushvalue(L, -1);

	lua_setfield(L, -2, "__index");

	luaL_setfuncs(L, lua_reg_member_funcs, 0);

	luaL_newlib(L, lua_reg_construct_funcs);

	return 1;
}
