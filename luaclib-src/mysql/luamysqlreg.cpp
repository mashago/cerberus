
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
#include <string.h>
#include "luamysqlreg.h"
}
// #include "logger.h"
#include "mysqlmgr.h"

static const char *METATABLE_NAME = "cerberus.mysql";

static int lcreate(lua_State *L)
{
	MysqlMgr **ptr = (MysqlMgr**)lua_newuserdata(L, sizeof(MysqlMgr *));
	*ptr = new MysqlMgr();

	luaL_getmetatable(L, METATABLE_NAME);
	lua_setmetatable(L, -2);

	return 1;
}

//////////////////////////////////////////////////////

static int lconnect(lua_State* L)
{
	MysqlMgr** s = (MysqlMgr**)luaL_checkudata(L, 1, METATABLE_NAME);
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, 2, LUA_TSTRING);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TSTRING);
	luaL_checktype(L, 5, LUA_TSTRING);
	luaL_checktype(L, 6, LUA_TSTRING);

	const char* ip = lua_tostring(L, 2);
	int port = (int)lua_tointeger(L, 3);
	const char* username = lua_tostring(L, 4);
	const char* password = lua_tostring(L, 5);
	const char* db_name = lua_tostring(L, 6);
	// LOG_DEBUG("ip=%s port=%d username=%s password=%s db_name=%s", ip, port, username, password, db_name);

	int ret = (*s)->Connect(ip, port, username, password, db_name);

	lua_pushinteger(L, ret);

	return 1;
}

static int lget_errno(lua_State* L)
{
	MysqlMgr** s = (MysqlMgr**)luaL_checkudata(L, 1, METATABLE_NAME);
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	int no = (*s)->GetErrno();

	lua_pushinteger(L, no);

	return 1;
}

static int lget_error(lua_State* L)
{
	MysqlMgr** s = (MysqlMgr**)luaL_checkudata(L, 1, METATABLE_NAME);
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	const char * error = (*s)->GetError();

	lua_pushstring(L, error);

	return 1;
}

static int lselect(lua_State* L)
{
	MysqlMgr** s = (MysqlMgr**)luaL_checkudata(L, 1, METATABLE_NAME);
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, 2, LUA_TSTRING);
	const char* sql = lua_tostring(L, 2);

	int ret = (*s)->Select(sql, strlen(sql));
	if (ret != 0)
	{
		int no = (*s)->GetErrno();
		const char * error = (*s)->GetError();
		printf("no=%d error=%s\n", no, error);
		lua_pushboolean(L, false);
		return 1;
	}

	lua_pushboolean(L, true);
	lua_newtable(L);

	int fieldCount = (*s)->FieldCount();
	// int numRows = (*s)->NumRows();
	// LOG_DEBUG("fieldCount=%d numRows=%d", fieldCount, numRows);

	MYSQL_FIELD *pField = (*s)->FetchField();
	MYSQL_ROW row;
	int index = 0;
	while ((row = (*s)->FetchRow()) != NULL)
	{
		++index;
		lua_newtable(L);
		std::string print_buffer = "";
		for (int j = 0; j < fieldCount; j++)
		{
			const char *row_value = "_Null";
			if (row[j]) row_value = row[j];
			print_buffer += std::string(pField[j].name) + std::string("=") + std::string(row_value) + std::string(" ");
			lua_pushstring(L, row_value);
			lua_setfield(L, -2, pField[j].name);
		}
		// LOG_DEBUG("line = [%s]", print_buffer.c_str());
		lua_rawseti(L, -2, index);
	}

	return 2;
}

static int lchange(lua_State* L)
{
	MysqlMgr** s = (MysqlMgr**)luaL_checkudata(L, 1, METATABLE_NAME);
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	luaL_checktype(L, 2, LUA_TSTRING);
	const char* sql = lua_tostring(L, 2);

	int ret = (*s)->Change(sql, strlen(sql));
	if (ret < 0)
	{
		int no = (*s)->GetErrno();
		const char * error = (*s)->GetError();
		printf("no=%d error=%s\n", no, error);
	}

	lua_pushinteger(L, ret);
	return 1;
}

static int lget_insert_id(lua_State* L)
{
	MysqlMgr** s = (MysqlMgr**)luaL_checkudata(L, 1, METATABLE_NAME);
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	int64_t insert_id = (*s)->GetInsertId();

	lua_pushinteger(L, insert_id);

	return 1;
}

static int lgc(lua_State *L)
{
	// LOG_DEBUG("do gc");
	MysqlMgr **s = (MysqlMgr**)luaL_checkudata(L, 1, METATABLE_NAME);
	luaL_argcheck(L, s != NULL, 1, "invalid user data");

	if (s)
	{
		delete *s;
	}
	return 0;
}

//////////////////////////////////////////////////////



// define constructor
static const luaL_Reg lua_reg_construct_funcs[] =
{
	{ "create", lcreate },
	{ NULL, NULL},
};

// define member functions
static const luaL_Reg lua_reg_member_funcs[] = 
{
	{ "connect", lconnect },
	{ "get_errno", lget_errno },
	{ "get_error", lget_error },
	{ "select", lselect },
	{ "change", lchange },
	{ "get_insert_id", lget_insert_id },
	{ "__gc", lgc },
	{ NULL, NULL },
};

int luaopen_cerberus_mysql(lua_State *L)
{
	luaL_checkversion(L);

	luaL_newmetatable(L, METATABLE_NAME);

	lua_pushvalue(L, -1);

	lua_setfield(L, -2, "__index");

	luaL_setfuncs(L, lua_reg_member_funcs, 0);

	luaL_newlib(L, lua_reg_construct_funcs);

	return 1;
}
