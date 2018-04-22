
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

static int luatimer_add_timer(lua_State *L)
{
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TBOOLEAN);

	int ms = (int)lua_tointeger(L, 2);
	bool is_loop = (bool)lua_toboolean(L, 3);

	lua_getglobal(L, "g_luaworld_ptr");
	LuaWorld **ptr = (LuaWorld **)lua_touserdata(L, -1);
	LuaWorld *luaworld = *ptr;
	lua_pop(L, 1);

	TimerMgr *timerMgr = luaworld->GetTimerMgr();

	int64_t new_timer_index = timerMgr->GetCurTimerIndex();
	int64_t ret_timer_index = timerMgr->AddTimer(ms, std::bind(&LuaWorld::HandleTimer, luaworld, std::placeholders::_1, std::placeholders::_2), (void *)new_timer_index, is_loop);

	lua_pushinteger(L, new_timer_index);
	lua_pushboolean(L, new_timer_index == ret_timer_index);

	return 2;
}

static int luatimer_del_timer(lua_State *L)
{
	luaL_checktype(L, 2, LUA_TNUMBER);
	int64_t timer_index = lua_tointeger(L, 2);

	lua_getglobal(L, "g_luaworld_ptr");
	LuaWorld **ptr = (LuaWorld **)lua_touserdata(L, -1);
	LuaWorld *luaworld = *ptr;
	lua_pop(L, 1);

	TimerMgr *timerMgr = luaworld->GetTimerMgr();

	bool ret = timerMgr->DelTimer(timer_index);

	lua_pushboolean(L, ret);

	return 1;
}

static const luaL_Reg lua_reg_funcs[] =
{
	{ "add_timer", luatimer_add_timer },
	{ "del_timer", luatimer_del_timer },
	{ NULL, NULL},
};

int luaopen_luatimer(lua_State *L)
{
	luaL_newlib(L, lua_reg_funcs);

	return 1;
}
