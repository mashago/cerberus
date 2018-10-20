
#include "luasubthread.h"

LuaSubThread::LuaSubThread()
{
}

LuaSubThread::~LuaSubThread()
{
}

bool LuaSubThread::Init(const char *file_name, const char *params, int len)
{
	m_L = luaL_newstate();
	if (!m_L)
	{
		return false;
	}

	// register lib
	const luaL_Reg lua_reg_libs[] = 
	{
		{ "base", luaopen_base },
		{ LUA_TABLIBNAME, luaopen_table },
		{ LUA_IOLIBNAME, luaopen_io },
		{ LUA_OSLIBNAME, luaopen_os },
		{ LUA_COLIBNAME, luaopen_coroutine },
		{ LUA_MATHLIBNAME, luaopen_math },
		{ LUA_DBLIBNAME, luaopen_debug },
		{ LUA_LOADLIBNAME, luaopen_package },
		{ LUA_STRLIBNAME, luaopen_string },
		{ NULL, NULL },
	};

	for (const luaL_Reg *libptr = lua_reg_libs; libptr->func; ++libptr)
	{
		luaL_requiref(m_L, libptr->name, libptr->func, 1);
		lua_pop(m_L, 1);
	}

	// push this to lua
	{
		LuaSubThread **ptr = (LuaSubThread **)lua_newuserdata(m_L, sizeof(LuaSubThread *));
		*ptr = this;
		lua_setglobal(m_L, "g_luasubthread_ptr");
	}

	if (LUA_OK != luaL_loadfile(m_L, "script/subthread/main.lua"))
	{
		const char * msg = lua_tostring(m_L, -1);
		LOG_ERROR("msg=%s", msg);
		return false;
	}
	lua_pushlstring(m_L, params, len);

	if (LUA_OK != lua_pcall(m_L, 1, LUA_MULTRET, 0))
	{
		const char * msg = lua_tostring(m_L, -1);
		LOG_ERROR("msg=%s", msg);
		return false;
	}

	return true;
}

void LuaSubThread::Dispatch()
{
	if (m_isRunning)
	{
		return;
	}
	auto thread_run = [](LuaSubThread *t)
	{
		while (t->m_isRunning)
		{
			t->HandleEvent();
		}
	};
	m_isRunning = true;
	m_thread = std::thread(thread_run, this);
}

void LuaSubThread::HandleEvent()
{
}
