
#include <string.h>
#include "luasubthread.h"
#include "event_pipe.h"
#include "logger.h"

LuaSubThread::LuaSubThread()
{
}

LuaSubThread::~LuaSubThread()
{
	// TODO
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
	lua_pushstring(m_L, file_name);
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
			t->RecvEvent();
		}
	};
	m_isRunning = true;
	m_thread = std::thread(thread_run, this);
}

void LuaSubThread::ReleaseJob(int64_t session_id, const char *func_name, const char *params, int len)
{
	EventNodeSubThreadJobReq *node = new EventNodeSubThreadJobReq;
	node->session_id = session_id;
	if (node->func_name && node->params)
	{
		node->func_name = strndup(func_name, strlen(func_name));
		node->params = strndup(params, len);
	}
	node->len = len;
	SendEvent(node);
}

void LuaSubThread::Destroy()
{
	m_isRunning = false;
	// release a null job
	ReleaseJob(0, NULL, NULL, 0);
}

void LuaSubThread::RecvEvent()
{
	const std::list<EventNode *> &eventList = m_inputPipe->Pop();
	for (auto iter = eventList.begin(); iter != eventList.end(); ++iter)
	{
		HandleEvent(**iter);
		delete *iter; // world new, sub thread delete
	}
}

void LuaSubThread::SendEvent(EventNode *node)
{
	m_outputPipe->Push(node);
}

void LuaSubThread::HandleEvent(const EventNode &node)
{
	switch (node.type)
	{
		case EVENT_TYPE::EVENT_TYPE_SUBTHREAD_JOB_REQ:
		{
			const EventNodeSubThreadJobReq &real_node = (EventNodeSubThreadJobReq&)node;
			if (real_node.func_name && real_node.params)
			{
				HandleJob(real_node.session_id, real_node.func_name, real_node.params, real_node.len);
			}
			break;
		}
		default:
			LOG_ERROR("cannot handle this node %d", node.type);
			break;
	}
}

void LuaSubThread::HandleJob(int64_t session_id, const char *func_name, const char *params, int n)
{
	LOG_DEBUG("session_id=%lld func_name=%s", session_id, func_name);
	if (1) 
	{
		return;
	}
	lua_getglobal(m_L, "ccall_handle_subthread_job");
	lua_pushinteger(m_L, session_id);
	lua_pushstring(m_L, func_name);
	lua_pushlstring(m_L, params, n);
	lua_call(m_L, 2, 0);
}
