#ifndef __NET_SERVER_H__
#define __NET_SERVER_H__

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
#include <map>
#include <list>
#include "mailbox.h"


class NetServer
{

public:
	NetServer();
	virtual ~NetServer();

	int LoadConfig(const char *path);
	int StartServer(const char *addr, unsigned int port);
	int Service(const char *addr, unsigned int port);

	virtual int HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen);
	virtual int HandleSocketConnected(evutil_socket_t fd);
	virtual int HandleSocketClosed(evutil_socket_t fd);
	virtual int HandleSocketError(evutil_socket_t fd);

	virtual int HandleSocketReadEvent(struct bufferevent *bev);
	virtual int HandleSocketReadMessage(struct bufferevent *bev);

	virtual int HandleSocketTickEvent();

	virtual int HandleRecvPluto();
	virtual int HandleSendPluto();

	virtual int HandlePluto(Pluto *u);

	inline MailBox *GetClientMailBox(int fd);

private:
	struct event_base *m_mainBase;
	struct event *m_timerEvent;
	struct evconnlistener *m_evconnlistener;

	std::map<int, MailBox*> m_fds;
	std::list<Pluto *> m_recvMsgs;

	int OnNewFdAccepted(int fd);
};

#endif
