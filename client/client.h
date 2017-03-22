
#ifndef __CLIENT_H__
#define __CLIENT_H__

extern "C"
{
#include <event2/event.h>
#include <event2/listener.h>
#include <event2/util.h>
#include <event2/bufferevent.h>
#include <event2/buffer.h>
}
#include "command.h"
#include <thread>
#include <mutex>
#include <list>
#include <string>

class Client
{
public:
	Client();
	~Client();

	bool Init(const char *addr, int port);
	bool Run();
	bool IsConnect();
	void SetConnect(bool flag);
	void PushCommand(Command *cmd);
	void HandleTickEvent();

private:
	bool CreateConnection();
	bool CreateTimer();
	void HandleCommand();
	Command *PopCommand();

	std::mutex m_mtx;
	std::thread m_thread;

	struct event_base *m_mainEvent;
	struct bufferevent *m_bev;
	struct event *m_timerEvent;

	std::list<Command *> m_cmdList;

	std::string m_addr;
	int m_port;
	bool m_bConnectFlag;
};

#endif
