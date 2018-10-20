
#pragma once
#include <lua.hpp>
#include <thread>

class EventPipe;
struct EventNode;

class LuaSubThread
{
public:
	LuaSubThread();
	~LuaSubThread();

	bool Init(const char *file_name, const char *params, int len);
	void Dispatch();
	void ReleaseJob(int64_t session_id, const char *func_name, const char *params, int len);
	void Destroy();

private:
	bool m_isRunning;
	EventPipe *m_inputPipe;
	EventPipe *m_outputPipe;
	std::thread m_thread;
	lua_State *m_L;

	void RecvEvent();
	void SendEvent(EventNode *node);
	void HandleEvent(const EventNode &node);
	void HandleJob(int64_t session_id, const char *func_name, const char *params, int len);

};
