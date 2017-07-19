
#pragma once

extern "C"
{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <time.h>
#include <errno.h>

#include <event2/event.h>
#include <event2/listener.h>
#include <event2/util.h>
#include <event2/bufferevent.h>
#include <event2/buffer.h>
}

#include <string>
#include <set>
#include <map>
#include <list>

#include "common.h"

class Pluto;
class Mailbox;
class EventPipe;
struct EventNode;

class NetService
{

public:
	NetService();
	~NetService();

	int Init(const char *addr, unsigned int port, std::set<std::string> &trustIpSet, EventPipe *net2worldPipe, EventPipe *world2netPipe);
	int Service();
	// return >= 0 as mailboxId, < 0 as error
	int64_t ConnectTo(const char *addr, unsigned int port);

	Mailbox *GetMailboxByFd(int fd);
	Mailbox *GetMailboxByMailboxId(int64_t mailboxId);

	int HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen);

	int HandleSocketRead(struct bufferevent *bev);
	int HandleSocketReadMessage(struct bufferevent *bev);
	void AddRecvMsg(Pluto *u);

	int HandleSocketConnectToSuccess(evutil_socket_t fd);
	int HandleSocketClosed(evutil_socket_t fd);
	int HandleSocketError(evutil_socket_t fd);

	void HandleWorldEvent();
	void HandleSendPluto();
	void HandleTickEvent();

	void SendEvent(EventNode *node);

	void CloseMailbox(int fd);
	void CloseMailbox(int64_t mailboxId);
	void CloseMailbox(Mailbox *pmb);

private:
	bool Listen(const char *addr, unsigned int port);
	Mailbox * NewMailbox(int fd, E_CONN_TYPE type);

	struct event_base *m_mainEvent;
	struct event *m_tickEvent;
	struct event *m_timerEvent;
	struct event *m_stdinEvent;
	struct evconnlistener *m_evconnlistener;

	std::map<int, Mailbox *> m_fds;
	std::map<int64_t, Mailbox *> m_mailboxs;
	std::list<Mailbox *> m_mb4del;
	std::set<int64_t> m_sendMailboxs;

	std::set<std::string> m_trustIpSet;
	EventPipe *m_net2worldPipe;
	EventPipe *m_world2netPipe;
};

