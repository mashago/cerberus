#ifndef __NET_SERVICE_H__
#define __NET_SERVICE_H__

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
#include "world.h"


class NetService
{

public:
	NetService();
	virtual ~NetService();

	int LoadConfig(const char *path);
	int Service(const char *addr, unsigned int port);
	MailBox *GetClientMailBox(int fd);
	void SetWorld(World *world);
	World *GetWorld();

	virtual int HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen);

	virtual int HandleSocketReadEvent(struct bufferevent *bev);
	virtual int HandleSocketReadMessage(struct bufferevent *bev);
	virtual void AddRecvMsg(Pluto *u);

	virtual int HandleSocketConnected(evutil_socket_t fd);
	virtual int HandleSocketClosed(evutil_socket_t fd);
	virtual int HandleSocketError(evutil_socket_t fd);

	virtual int HandleSocketTickEvent();
	virtual int HandleRecvPluto();
	virtual int HandleSendPluto();


private:
	int StartService(const char *addr, unsigned int port);
	int OnNewFdAccepted(int fd);
	void AddFdAndMb(int fd, EFDTYPE type);
	void AddFdAndMb(int fd, MailBox *pmb);
	void RemoveFd(int fd);
	void CloseFd(int fd);

	struct event_base *m_mainEvent;
	struct event *m_timerEvent;
	struct evconnlistener *m_evconnlistener;

	std::map<int, MailBox *> m_fds;
	std::list<MailBox *> m_mb4del;
	std::list<Pluto *> m_recvMsgs;
	World *m_world;
};

#endif
