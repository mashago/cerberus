
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "util.h"

int luautil_get_time_ms(lua_State *L)
{
	struct timeval tv;    
	gettimeofday(&tv, NULL);
	int64_t time_ms = tv.tv_sec * 1000.0 + tv.tv_usec / 1000.0;
	lua_pushnumber(L, time_ms);

	return 1;
}

static const luaL_Reg lua_reg_funcs[] =
{
	{ "get_time_ms", luautil_get_time_ms },
	{ NULL, NULL},
};

int luaopen_luautil(lua_State *L)
{
	luaL_newmetatable(L, "LuaUtil");

	lua_pushvalue(L, -1);

	lua_setfield(L, -2, "__index");

	luaL_newlib(L, lua_reg_funcs);

	return 1;
}
