
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include <functional>
#include "logger.h"
#include "luatimerreg.h"
#include "timermgr.h"
#include "luaworld.h"

static int ladd_timer(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TNUMBER);
	luaL_checktype(L, 2, LUA_TBOOLEAN);

	int ms = (int)lua_tointeger(L, 1);
	bool is_loop = (bool)lua_toboolean(L, 2);

	LuaWorld *world = (LuaWorld *)lua_touserdata(L, lua_upvalueindex(1));
	TimerMgr *timerMgr = world->GetTimerMgr();

	int64_t new_timer_index = timerMgr->GetCurTimerIndex();
	int64_t ret_timer_index = timerMgr->AddTimer(ms, std::bind(&LuaWorld::HandleTimer, world, std::placeholders::_1, std::placeholders::_2), (void *)new_timer_index, is_loop);

	lua_pushinteger(L, new_timer_index);
	lua_pushboolean(L, new_timer_index == ret_timer_index);

	return 2;
}

static int ldel_timer(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TNUMBER);
	int64_t timer_index = lua_tointeger(L, 1);

	LuaWorld *world = (LuaWorld *)lua_touserdata(L, lua_upvalueindex(1));
	TimerMgr *timerMgr = world->GetTimerMgr();
	bool ret = timerMgr->DelTimer(timer_index);
	lua_pushboolean(L, ret);

	return 1;
}

static const luaL_Reg lua_reg_funcs[] =
{
	{ "add_timer", ladd_timer },
	{ "del_timer", ldel_timer },
	{ NULL, NULL},
};

int luaopen_cerberus_timer(lua_State *L)
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
