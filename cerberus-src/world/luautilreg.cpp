
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "util.h"
#include "logger.h"

static int lget_time_ms(lua_State *L)
{
	struct timeval tv;    
	gettimeofday(&tv, NULL);
	int64_t time_ms = int64_t(tv.tv_sec * 1000.0 + tv.tv_usec / 1000.0);
	lua_pushinteger(L, time_ms);

	return 1;
}

static int llog(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TNUMBER);
	luaL_checktype(L, 2, LUA_TSTRING);

	int type = lua_tointeger(L, 1);
	const char * str =  lua_tostring(L, 2);

	switch (type)
	{
		case LOG_TYPE_DEBUG:
		{
			LOG_RAW_STRING(LOG_TYPE_DEBUG, __FILE__, __FUNCTION__, 0,  str);
			break;
		}
		case LOG_TYPE_INFO:
		{
			LOG_RAW_STRING(LOG_TYPE_INFO, __FILE__, __FUNCTION__, 0, str);
			break;
		}
		case LOG_TYPE_WARN:
		{
			LOG_RAW_STRING(LOG_TYPE_WARN, __FILE__, __FUNCTION__, 0, str);
			break;
		}
		case LOG_TYPE_ERROR:
		{
			LOG_RAW_STRING(LOG_TYPE_ERROR, __FILE__, __FUNCTION__, 0, str);
			break;
		}
	};
	
	return 0;
}

static int lsleep(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TNUMBER);
	int second = lua_tointeger(L, 1);
	sleep(second);
	return 0;
}

static const luaL_Reg lua_reg_funcs[] =
{
	{ "get_time_ms", lget_time_ms },
	{ "log", llog },
	{ "sleep", lsleep },
	{ NULL, NULL},
};

int luaopen_cerberus_util(lua_State *L)
{
	luaL_newlib(L, lua_reg_funcs);

	return 1;
}
