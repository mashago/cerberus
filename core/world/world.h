
#pragma once

#include <thread>

class EventPipe;
struct EventNode;
class TimerMgr;
class Pluto;

class World
{
public:
	World();
	virtual ~World();

	bool Init(int server_id, int server_type, const char *conf_file, const char * entry_path, EventPipe *inputPipe, EventPipe *outputPipe);
	void Dispatch();

	virtual void HandleNewConnection(int64_t mailboxId, const char *ip, int port) = 0;
	virtual void HandleConnectToSuccess(int64_t mailboxId) = 0;
	virtual void HandleDisconnect(int64_t mailboxId) = 0;
	virtual void HandleMsg(Pluto &u) = 0;
	virtual void HandleStdin(const char *buffer);
	virtual void HandleConnectToRet(int64_t index, int64_t mailboxId) = 0;
	virtual void HandleHttpResponse(int64_t session_id, int response_code, const char *content, int content_len) = 0;

	void RecvEvent();
	void SendEvent(EventNode *node);

	TimerMgr *GetTimerMgr()
	{
		return m_timerMgr;
	}

private:
	bool m_isRunning;
	EventPipe *m_inputPipe;
	EventPipe *m_outputPipe;
	TimerMgr *m_timerMgr;
	std::thread m_thread;

	void SetEventPipe(EventPipe *inputPipe, EventPipe *outputPipe);
	virtual bool CoreInit(int server_id, int server_type, const char *conf_file, const char * entry_path);
	void HandleEvent(const EventNode &node);
};

