
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "common.h"
#include "logger.h"
#include "pluto.h"
#include "luaworld.h"
#include "luanetworkreg.h"
#include "luanetwork.h"

static LuaNetwork *get_network(lua_State* L)
{
	LuaWorld *world = (LuaWorld *)lua_touserdata(L, lua_upvalueindex(1));
	return world->GetNetwork();
}

static int lwrite_msg_id(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TNUMBER);
	network->GetSendPluto()->WriteMsgId(lua_tointeger(L, 1));

	return 0;
}

static int lwrite_ext(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TNUMBER);
	network->GetSendPluto()->WriteExt(lua_tointeger(L, 1));

	return 0;
}

static int lwrite_byte(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TNUMBER);
	bool ret = network->GetSendPluto()->WriteByte((char)lua_tointeger(L, 1));
	lua_pushboolean(L, ret);

	return 1;
}

static int lwrite_int(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TNUMBER);
	bool ret = network->GetSendPluto()->WriteInt((int)lua_tointeger(L, 1));
	lua_pushboolean(L, ret);

	return 1;
}

static int lwrite_float(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TNUMBER);
	bool ret = network->GetSendPluto()->WriteFloat((float)lua_tonumber(L, 1));
	lua_pushboolean(L, ret);

	return 1;
}

static int lwrite_bool(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TBOOLEAN);
	bool ret = network->GetSendPluto()->WriteBool(lua_toboolean(L, 1) != 0);
	lua_pushboolean(L, ret);

	return 1;
}

static int lwrite_short(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TNUMBER);
	bool ret = network->GetSendPluto()->WriteShort((short)lua_tointeger(L, 1));
	lua_pushboolean(L, ret);

	return 1;
}

static int lwrite_int64(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TNUMBER);
	bool ret = network->GetSendPluto()->WriteInt64(lua_tointeger(L, 1));
	lua_pushboolean(L, ret);

	return 1;
}


static int lwrite_string(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TSTRING);
	bool ret = network->GetSendPluto()->WriteString((int)luaL_len(L,1), lua_tostring(L, 1));
	lua_pushboolean(L, ret);

	return 1;
}


#define write_table_len(len) \
do { \
len = (int)luaL_len(L, 1); \
bool ret = network->GetSendPluto()->WriteInt(len); \
if (!ret) \
{ \
	lua_pushboolean(L, ret); \
	return 1; \
} \
} while (false)

static int lwrite_byte_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TTABLE);
	int len = 0;
	write_table_len(len);

	for (int i = 1; i <= len; ++i)
	{
		lua_pushinteger(L,i);
		lua_rawget(L, 1);
		bool ret = network->GetSendPluto()->WriteByte((char)lua_tointeger(L, -1));
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

static int lwrite_int_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TTABLE);
	int len = 0;
	write_table_len(len);

	for (int i = 1; i <= len; ++i)
	{
		lua_pushinteger(L, i);
		lua_rawget(L, 1);
		bool ret = network->GetSendPluto()->WriteInt((int)lua_tointeger(L, -1));
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

static int lwrite_float_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TTABLE);
	int len = 0;
	write_table_len(len);

	for (int i = 1; i <= len; ++i){
		lua_pushinteger(L, i);
		lua_rawget(L, 1);
		bool ret = network->GetSendPluto()->WriteFloat((float)lua_tonumber(L,-1));
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

static int lwrite_bool_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TTABLE);
	int len = 0;
	write_table_len(len);

	for (int i = 1; i <= len; ++i){
		lua_pushinteger(L, i);
		lua_rawget(L, 1);
		bool ret = network->GetSendPluto()->WriteBool(lua_toboolean(L, -1) != 0);
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

static int lwrite_short_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TTABLE);
	int len = 0;
	write_table_len(len);

	for (int i = 1; i <= len; ++i){
		lua_pushinteger(L, i);
		lua_rawget(L, 1);
		bool ret = network->GetSendPluto()->WriteShort((short)lua_tointeger(L, -1));
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

static int lwrite_int64_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TTABLE);
	int len = 0;
	write_table_len(len);

	for (int i = 1; i <= len; ++i){
		lua_pushinteger(L, i);
		lua_rawget(L, 1);
		bool ret = network->GetSendPluto()->WriteInt64(lua_tointeger(L, -1));
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

static int lwrite_string_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TTABLE);
	int len = 0;
	write_table_len(len);

	for (int i = 1; i <= len; ++i){
		lua_pushinteger(L, i);
		lua_rawget(L, 1);
		bool ret = network->GetSendPluto()->WriteString((int)luaL_len(L, -1), lua_tostring(L, -1));
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

static int lclear_write(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	network->GetSendPluto()->Cleanup();
	lua_pushboolean(L, true);

	return 1;
}

static int lsend(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TNUMBER);
	bool ret = network->Send(lua_tointeger(L, 1));
	lua_pushboolean(L, ret);

	return 1;
}

static int ltransfer(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TNUMBER);
	bool ret = network->Transfer(lua_tointeger(L, 1));
	lua_pushboolean(L, ret);

	return 1;
}

//////////////////////////////////////////////////////

static int lread_msg_id(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	int msg_id = network->GetRecvPluto()->ReadMsgId();
	lua_pushinteger(L, msg_id);

	return 1;
}

static int lread_ext(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	lua_pushinteger(L, network->GetRecvPluto()->ReadExt());

	return 1;
}

static int lread_byte(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	char out_val = 0;
	bool ret = network->GetRecvPluto()->ReadByte(out_val);
	lua_pushboolean(L, ret);
	lua_pushinteger(L, out_val);

	return 2;
}

static int lread_int(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	int out_val = 0;
	bool ret = network->GetRecvPluto()->ReadInt(out_val);
	lua_pushboolean(L, ret);
	lua_pushinteger(L, out_val);

	return 2;
}

static int lread_float(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	float out_val = 0;
	bool ret = network->GetRecvPluto()->ReadFloat(out_val);
	lua_pushboolean(L, ret);
	lua_pushnumber(L, out_val);

	return 2;
}

static int lread_bool(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	bool out_val = false;
	bool ret = network->GetRecvPluto()->ReadBool(out_val);
	lua_pushboolean(L, ret);
	lua_pushboolean(L, out_val);

	return 2;
}

static int lread_int64(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	int64_t out_val = 0;
	bool ret = network->GetRecvPluto()->ReadInt64(out_val);
	lua_pushboolean(L, ret);
	lua_pushinteger(L, out_val);

	return 2;
}

static int lread_short(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	short out_val = 0;
	bool ret = network->GetRecvPluto()->ReadShort(out_val);
	lua_pushboolean(L, ret);
	lua_pushinteger(L, out_val);

	return 2;
}

static int lread_string(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	int out_len = 0;
	char out_val[MSGLEN_MAX+1] = {};
	bool ret = network->GetRecvPluto()->ReadString(out_len, out_val);
	lua_pushboolean(L, ret);
	lua_pushlstring(L, out_val, out_len);

	return 2;
}

static int lread_byte_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	int len = 0;
	bool ret = network->GetRecvPluto()->ReadInt(len);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);
	for (int i = 1; i <= len; ++i){
		char out_val = 0;
		bool ret = network->GetRecvPluto()->ReadByte(out_val);
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

static int lread_int_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);

	int len = 0;
	bool ret = network->GetRecvPluto()->ReadInt(len);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);
	for (int i = 1; i <= len; ++i){
		int out_val = 0;
		bool ret = network->GetRecvPluto()->ReadInt(out_val);
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

static int lread_float_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);

	int len = 0;
	bool ret = network->GetRecvPluto()->ReadInt(len);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);
	for (int i = 1; i <= len; ++i){
		float out_val = 0;
		bool ret = network->GetRecvPluto()->ReadFloat(out_val);
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

static int lread_bool_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);

	int len = 0;
	bool ret = network->GetRecvPluto()->ReadInt(len);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);
	for (int i = 1; i <= len; ++i){
		bool out_val = 0;
		bool ret = network->GetRecvPluto()->ReadBool(out_val);
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

static int lread_int64_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);

	int len = 0;
	bool ret = network->GetRecvPluto()->ReadInt(len);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);
	for (int i = 1; i <= len; ++i){
		int64_t out_val = 0;
		bool ret = network->GetRecvPluto()->ReadInt64(out_val);
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

static int lread_short_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);

	int len = 0;
	bool ret = network->GetRecvPluto()->ReadInt(len);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);
	for (int i = 1; i <= len; ++i){
		short out_val = 0;
		bool ret = network->GetRecvPluto()->ReadShort(out_val);
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

static int lread_string_array(lua_State* L)
{
	LuaNetwork *network = get_network(L);

	int len = 0;
	bool ret = network->GetRecvPluto()->ReadInt(len);
	if (!ret)
	{
		lua_pushboolean(L, ret);
		return 1;
	}

	lua_newtable(L);
	for (int i = 1; i <= len; ++i){
		int out_len = 0;
		char out_val[MSGLEN_MAX+1] = {};
		bool ret = network->GetRecvPluto()->ReadString(out_len, out_val);
		if (!ret)
		{
			lua_pushboolean(L, ret);
			lua_insert(L, -2);
			return 2;
		}

		lua_pushinteger(L, i);
		lua_pushlstring(L, out_val, out_len);
		lua_rawset(L, -3);
	}

	lua_pushboolean(L, ret);
	lua_insert(L, -2);

	return 2;
}

static int lconnect_to(lua_State* L)
{
	LuaNetwork *network = get_network(L);

	luaL_checktype(L, 1, LUA_TSTRING);
	luaL_checktype(L, 2, LUA_TNUMBER);
	const char* ip = lua_tostring(L, 1);
	int port = (int)lua_tointeger(L, 2);
	LOG_DEBUG("ip=%s port=%d", ip, port);

	int64_t connect_index = network->ConnectTo(ip, port);

	lua_pushboolean(L, connect_index >= 0);
	lua_pushinteger(L, connect_index);

	return 2;
}

static int lclose_mailbox(lua_State* L)
{
	LuaNetwork *network = get_network(L);
	luaL_checktype(L, 1, LUA_TNUMBER);
	int64_t mailboxId = lua_tointeger(L, 1);
	network->CloseMailbox(mailboxId);

	return 0;
}

static int lhttp_request(lua_State* L)
{
	LuaNetwork *network = get_network(L);

	// url, session_id, request_type, post_data, post_data_len
	luaL_checktype(L, 1, LUA_TSTRING);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TSTRING);
	luaL_checktype(L, 5, LUA_TNUMBER);

	const char *url = lua_tostring(L, 1);
	int64_t session_id = lua_tointeger(L, 2);
	int request_type = lua_tointeger(L, 3);
	const char *post_data = lua_tostring(L, 4);
	int post_data_len = lua_tointeger(L, 5);

	bool ret = network->HttpRequest(url, session_id, request_type, post_data, post_data_len);

	lua_pushboolean(L, ret);

	return 1;
}

static int llisten(lua_State* L)
{
	LuaNetwork *network = get_network(L);

	// session_id, ip, port
	luaL_checktype(L, 1, LUA_TNUMBER);
	luaL_checktype(L, 2, LUA_TSTRING);
	luaL_checktype(L, 3, LUA_TNUMBER);

	int64_t session_id = lua_tointeger(L, 1);
	const char* ip = lua_tostring(L, 2);
	int port = (int)lua_tointeger(L, 3);
	LOG_DEBUG("ip=%s port=%d session_id=%ld", ip, port, session_id);

	bool ret = network->Listen(ip, port, session_id);

	lua_pushboolean(L, ret);

	return 1;
}

//////////////////////////////////////////////////////


// define member functions
static const luaL_Reg lua_reg_funcs[] = 
{
	{ "write_msg_id", lwrite_msg_id },
	{ "write_ext", lwrite_ext },
	{ "write_byte", lwrite_byte },
	{ "write_int", lwrite_int },
	{ "write_float", lwrite_float },
	{ "write_bool", lwrite_bool },
	{ "write_short", lwrite_short },
	{ "write_int64", lwrite_int64 },
	{ "write_string", lwrite_string },

	{ "write_byte_array", lwrite_byte_array },
	{ "write_int_array", lwrite_int_array },
	{ "write_float_array", lwrite_float_array },
	{ "write_bool_array", lwrite_bool_array },
	{ "write_short_array", lwrite_short_array },
	{ "write_int64_array", lwrite_int64_array },
	{ "write_string_array", lwrite_string_array },

	{ "clear_write", lclear_write },
	{ "send", lsend },
	{ "transfer", ltransfer },

	{ "read_msg_id", lread_msg_id },
	{ "read_ext", lread_ext },
	{ "read_byte", lread_byte },
	{ "read_int", lread_int },
	{ "read_float", lread_float },
	{ "read_bool", lread_bool },
	{ "read_int64", lread_int64 },
	{ "read_short", lread_short },
	{ "read_string", lread_string },

	{ "read_byte_array", lread_byte_array },
	{ "read_int_array", lread_int_array },
	{ "read_float_array", lread_float_array },
	{ "read_bool_array", lread_bool_array },
	{ "read_int64_array", lread_int64_array },
	{ "read_short_array", lread_short_array },
	{ "read_string_array", lread_string_array },

	{ "connect_to", lconnect_to },
	{ "close_mailbox", lclose_mailbox },

	{ "http_request", lhttp_request },
	{ "listen", llisten },

	{ NULL, NULL },
};

int luaopen_cerberus_network(lua_State *L)
{
	// new lib table
	luaL_newlibtable(L, lua_reg_funcs);

	// get world from registry
	lua_getfield(L, LUA_REGISTRYINDEX, "cerberus_world");
	LuaWorld *world = (LuaWorld *)lua_touserdata(L, -1); 
	if (!world)
	{
		return luaL_error(L, "nil world");
	}

	// set lib funcs, and set world as upvalue
	luaL_setfuncs(L, lua_reg_funcs, 1);

	return 1;
}
