
extern "C"
{
#include <string.h>
#include <lauxlib.h>
#include <lualib.h>
#include "lfs.h"
}
#include "util.h"
#include "logger.h"
#include "pluto.h"
#include "mailbox.h"
#include "luaworld.h"
#include "event_pipe.h"
#include "luanetworkreg.h"
#include "luanetwork.h"
#include "luatinyxmlreg.h"
#include "luamysqlmgrreg.h"
#include "luatimerreg.h"
#include "luautilreg.h"
#include "luasubthread.h"
#include "timermgr.h"

LuaWorld::LuaWorld() : 
m_isRunning(false),
m_inputPipe(nullptr),
m_outputPipe(nullptr),
m_timerMgr(nullptr),
m_L(nullptr),
m_luanetwork(nullptr),
m_connIndex(0)
{
	m_timerMgr = new TimerMgr();
}

LuaWorld::~LuaWorld()
{
	m_isRunning = false;
	m_thread.join();
	delete m_timerMgr;
	delete m_luanetwork;
}

bool LuaWorld::Init(const char *conf_file, EventPipe *inputPipe, EventPipe *outputPipe)
{
	m_inputPipe = inputPipe;
	m_outputPipe = outputPipe;

	m_luanetwork = new LuaNetwork(this);

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
		{ "LuaNetwork", luaopen_luanetwork },
		{ "LuaTinyXMLDoc", luaopen_luatinyxmldoc },
		{ "LuaTinyXMLEle", luaopen_luatinyxmlele },
		{ "LuaMysqlMgr", luaopen_luamysqlmgr },
		{ "LuaTimer", luaopen_luatimer },
		{ "LuaUtil", luaopen_luautil },
		{ "lfs", luaopen_lfs },
		{ NULL, NULL },
	};

	for (const luaL_Reg *libptr = lua_reg_libs; libptr->func; ++libptr)
	{
		luaL_requiref(m_L, libptr->name, libptr->func, 1);
		lua_pop(m_L, 1);
	}

	// push this to lua
	{
		LuaWorld **ptr = (LuaWorld **)lua_newuserdata(m_L, sizeof(LuaWorld *));
		*ptr = this;
		lua_setglobal(m_L, "g_luaworld_ptr");
	}

	// push luanetwork to lua
	{
		LuaNetwork **ptr = (LuaNetwork **)lua_newuserdata(m_L, sizeof(LuaNetwork *));
		*ptr = m_luanetwork;
		lua_setglobal(m_L, "g_luanetwork_ptr");
	}

	if (LUA_OK != luaL_loadfile(m_L, "script/main.lua"))
	{
		const char * msg = lua_tostring(m_L, -1);
		LOG_ERROR("msg=%s", msg);
		return false;
	}
	lua_pushstring(m_L, conf_file);

	if (LUA_OK != lua_pcall(m_L, 1, LUA_MULTRET, 0))
	{
		const char * msg = lua_tostring(m_L, -1);
		LOG_ERROR("msg=%s", msg);
		return false;
	}

	return true;
}

void LuaWorld::Dispatch()
{
	if (m_isRunning)
	{
		return;
	}
	auto world_run = [](LuaWorld *world)
	{
		while (world->m_isRunning)
		{
			world->RecvEvent();
		}
	};
	m_isRunning = true;
	m_thread = std::thread(world_run, this);
}

////////////////////////////////////////

void LuaWorld::RecvEvent()
{
	const std::list<EventNode *> &eventList = m_inputPipe->Pop();
	for (auto iter = eventList.begin(); iter != eventList.end(); ++iter)
	{
		HandleEvent(**iter);
		delete *iter; // net new, world delete
	}
}

void LuaWorld::SendEvent(EventNode *node)
{
	m_outputPipe->Push(node);
}

void LuaWorld::HandleEvent(const EventNode &node)
{
	switch (node.type)
	{
		case EVENT_TYPE::EVENT_TYPE_NEW_CONNECTION:
		{
			const EventNodeNewConnection &real_node = (EventNodeNewConnection&)node;
			HandleNewConnection(real_node.mailboxId, real_node.ip, real_node.port);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_CONNECT_TO_SUCCESS:
		{
			const EventNodeConnectToSuccess &real_node = (EventNodeConnectToSuccess&)node;
			HandleConnectToSuccess(real_node.mailboxId);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_DISCONNECT:
		{
			const EventNodeDisconnect &real_node = (EventNodeDisconnect&)node;
			HandleDisconnect(real_node.mailboxId);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_TIMER:
		{
			// const EventNodeTimer &real_node = (EventNodeTimer&)node;
			m_timerMgr->Update();
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_MSG:
		{
			const EventNodeMsg &real_node = (EventNodeMsg&)node;
			HandleMsg(*real_node.pu);
			delete real_node.pu; // net new, world delete
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_STDIN:
		{
			const EventNodeStdin &real_node = (EventNodeStdin&)node;
			HandleStdin(real_node.buffer);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_CONNECT_TO_RET:
		{
			const EventNodeConnectToRet &real_node = (EventNodeConnectToRet&)node;
			HandleConnectToRet(real_node.ext, real_node.mailboxId);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_HTTP_RSP:
		{
			const EventNodeHttpRsp &real_node = (EventNodeHttpRsp&)node;
			HandleHttpResponse(real_node.session_id, real_node.response_code, real_node.content, real_node.content_len);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_LISTEN_RET:
		{
			const EventNodeListenRet &real_node = (EventNodeListenRet&)node;
			HandleListenRet(real_node.listenId, real_node.session_id);
			break;
		}
		default:
			LOG_ERROR("cannot handle this node %d", node.type);
			break;
	}
}

void LuaWorld::HandleNewConnection(int64_t mailboxId, const char *ip, int port)
{
	LOG_DEBUG("mailboxId=%ld ip=%s port=%d", mailboxId, ip, port);

	lua_getglobal(m_L, "ccall_new_connection");
	lua_pushinteger(m_L, mailboxId);
	lua_pushstring(m_L, ip);
	lua_pushinteger(m_L, port);
	lua_call(m_L, 3, 0);
}

void LuaWorld::HandleDisconnect(int64_t mailboxId)
{
	LOG_DEBUG("mailboxId=%ld", mailboxId);

	lua_getglobal(m_L, "ccall_disconnect_handler");
	lua_pushinteger(m_L, mailboxId);
	lua_call(m_L, 1, 0);
}

void LuaWorld::HandleConnectToSuccess(int64_t mailboxId)
{
	LOG_DEBUG("mailboxId=%ld", mailboxId);

	lua_getglobal(m_L, "ccall_connect_to_success_handler");
	lua_pushinteger(m_L, mailboxId);
	lua_call(m_L, 1, 0);
}

void LuaWorld::HandleMsg(Pluto &u)
{
	int64_t mailboxId = u.GetMailboxId();
	int msgId = u.ReadMsgId();
	// LOG_DEBUG("mailboxId=%ld msgId=%d", mailboxId, msgId);

	m_luanetwork->SetRecvPluto(&u);
	lua_getglobal(m_L, "ccall_recv_msg_handler");
	lua_pushinteger(m_L, mailboxId);
	lua_pushinteger(m_L, msgId);
	lua_call(m_L, 2, 0);
}

void LuaWorld::HandleStdin(const char *buffer)
{
	// default do nothing
}

void LuaWorld::HandleConnectToRet(int64_t connIndex, int64_t mailboxId)
{
	LOG_DEBUG("connIndex=%ld mailboxId=%ld", connIndex, mailboxId);

	lua_getglobal(m_L, "ccall_connect_to_ret_handler");
	lua_pushinteger(m_L, connIndex);
	lua_pushinteger(m_L, mailboxId);
	lua_call(m_L, 2, 0);
}

void LuaWorld::HandleHttpResponse(int64_t session_id, int response_code, const char *content, int content_len)
{
	// LOG_DEBUG("session_id=%ld response_code=%d content_len=%d content=%s", session_id, response_code, content_len, content);

	lua_getglobal(m_L, "ccall_http_response_handler");
	lua_pushinteger(m_L, session_id);
	lua_pushinteger(m_L, response_code);
	if (content)
	{
		lua_pushlstring(m_L, content, content_len);
	}
	else
	{
		lua_pushstring(m_L, "");
	}
	lua_call(m_L, 3, 0);
}

void LuaWorld::HandleListenRet(int64_t listenId, int64_t session_id)
{
	LOG_DEBUG("listenId=%ld session_id=%ld", listenId, session_id);

	lua_getglobal(m_L, "ccall_listen_ret_handler");
	lua_pushinteger(m_L, listenId);
	lua_pushinteger(m_L, session_id);
	lua_call(m_L, 2, 0);
}

void LuaWorld::HandleTimer(void *arg, bool is_loop)
{
	int64_t timer_index = (int64_t)arg;
	// LOG_DEBUG("timer_index=%ld", timer_index);

	lua_getglobal(m_L, "ccall_timer_handler");
	lua_pushinteger(m_L, timer_index);
	lua_pushboolean(m_L, is_loop);
	lua_call(m_L, 2, 0);
}

//////////////////////////////////////////////

// send a eventnode to net, return a connect index for connect to ret event
int64_t LuaWorld::ConnectTo(const char* ip, unsigned int port)
{
	EventNodeConnectToReq *node = new EventNodeConnectToReq;
	snprintf(node->ip, sizeof(node->ip), "%s", ip);
	node->port = port;
	node->ext = ++m_connIndex;
	SendEvent(node);
	return m_connIndex;
}

void LuaWorld::SendPluto(Pluto *pu)
{
	EventNodeMsg *node = new EventNodeMsg;
	node->pu = pu;
	SendEvent(node);
}

void LuaWorld::CloseMailbox(int64_t mailboxId)
{
	EventNodeDisconnect *node = new EventNodeDisconnect;
	node->mailboxId = mailboxId;
	SendEvent(node);
}

bool LuaWorld::HttpRequest(const char *url, int64_t session_id, int request_type, const char *post_data, int post_data_len)
{
	EventNodeHttpReq *node = new EventNodeHttpReq;
	int len = (int)strlen(url) + 1;
	char *url_ptr = new char[len];
	memcpy(url_ptr, url, len);

	char *post_data_ptr = NULL;
	if (post_data_len == 0)
	{
		post_data_ptr = new char[post_data_len];
		memcpy(post_data_ptr, post_data, post_data_len);
	}

	node->url = url_ptr;
	node->session_id = session_id;
	node->request_type = request_type;
	node->post_data = post_data_ptr;
	node->post_data_len = post_data_len;
	SendEvent(node);

	return true;
}

bool LuaWorld::Listen(const char* ip, unsigned int port, int64_t session_id)
{
	EventNodeListenReq *node = new EventNodeListenReq;
	snprintf(node->ip, sizeof(node->ip), "%s", ip);
	node->port = port;
	node->session_id = session_id;
	SendEvent(node);
	return true;
}

int LuaWorld::CreateSubThread(const char *file_name, const char *params, int len)
{
	static int uuid = 1;
	LuaSubThread *ptr = new LuaSubThread;
	if (!ptr->Init(file_name, params, len))
	{
		delete ptr;
		return -1;
	}
	m_subthread_map.insert(std::make_pair(uuid, ptr));
	uuid += 1;
	return uuid;
}

void LuaWorld::CallSubThread(int thread_id, int64_t session_id, const char *func_name, const char *params, int len)
{
	auto it = m_subthread_map.find(thread_id);
	if (it == m_subthread_map.end())
	{
		return;
	}
	it->second->ReleaseJob(session_id, func_name, params, len);
}

void LuaWorld::DestroySubThread(int thread_id)
{
	auto it = m_subthread_map.find(thread_id);
	if (it == m_subthread_map.end())
	{
		return;
	}
	it->second->Destroy();
	m_subthread_map.erase(it);
}


