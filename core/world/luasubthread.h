
#pragma once
#include <lua.hpp>
#include <thread>

class LuaSubThread
{
public:
	LuaSubThread();
	~LuaSubThread();

	bool Init(const char *file_name, const char *params, int len);
	void Dispatch();
	void Call(int64_t session_id, const char *func_name, const char *params, int n);
	void Destroy();
	void HandleEvent();
private:
	bool m_isRunning;
	EventPipe *m_inputPipe;
	EventPipe *m_outputPipe;
	std::thread m_thread;
};
