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


class NetService
{

public:
	NetService();
	virtual ~NetService();

	int LoadConfig(const char *path);
	int Service(const char *addr, unsigned int port);

	virtual int HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen);
	virtual int HandleSocketReadEvent(struct bufferevent *bev);
	virtual int HandleSocketConnected(evutil_socket_t fd);
	virtual int HandleSocketClosed(evutil_socket_t fd);
	virtual int HandleSocketError(evutil_socket_t fd);

private:
	int StartServer(const char *addr, unsigned int port);
	struct event_base *m_mainEvent;
	struct evconnlistener *m_evconnlistener;

};

#endif
