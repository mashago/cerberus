
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
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

static const luaL_Reg lua_reg_construct_funcs[] =
{
	{ "instance", luanetwork_instance },
	{ NULL, NULL},
};

static const luaL_Reg lua_reg_member_funcs[] =
{
	{ NULL, NULL},
};

int luaopen_luanetwork_libs(lua_State *L)
{
	luaL_newmetatable(L, "LuaNetwork");

	lua_pushvalue(L, -1);

	lua_setfield(L, -2, "__index");

	luaL_setfuncs(L, lua_reg_member_funcs, 0);

	luaL_newlib(L, lua_reg_construct_funcs);

	return 1;
}
