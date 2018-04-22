
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "util.h"
#include "logger.h"

static int luautil_get_time_ms(lua_State *L)
{
	struct timeval tv;    
	gettimeofday(&tv, NULL);
	int64_t time_ms = tv.tv_sec * 1000.0 + tv.tv_usec / 1000.0;
	lua_pushnumber(L, time_ms);

	return 1;
}

static int luautil_log(lua_State *L)
{
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TSTRING);

	int type = lua_tointeger(L, 2);
	const char * str =  lua_tostring(L, 3);

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

static const luaL_Reg lua_reg_funcs[] =
{
	{ "get_time_ms", luautil_get_time_ms },
	{ "log", luautil_log },
	{ NULL, NULL},
};

int luaopen_luautil(lua_State *L)
{
	luaL_newlib(L, lua_reg_funcs);

	return 1;
}
