
#pragma once

extern "C"
{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#ifdef WIN32
#include <io.h>  
#include <process.h>
#include <winsock2.h>
#else
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#endif
#include <sys/types.h>
#include <time.h>
#include <errno.h>

#include <event2/util.h>
}

#include <string>
#include <set>
#include <map>
#include <list>

#include "common.h"

struct event_base;
struct event;
struct bufferevent;
struct evconnlistener;
struct evdns_base;
struct evhttp_connection;

class Pluto;
class Mailbox;
class EventPipe;
struct EventNode;

class NetService
{
public:
	NetService();
	~NetService();

	int Init(const char *addr, unsigned int port, int maxConn, std::set<std::string> &trustIpSet, EventPipe *net2worldPipe, EventPipe *world2netPipe);
	int Dispatch();

	// return >= 0 as mailboxId, < 0 as error
	int64_t ConnectTo(const char *addr, unsigned int port);
	bool Listen(const char *addr, unsigned int port);

	void SendEvent(EventNode *node);
	int HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen);
	int HandleSocketRead(struct bufferevent *bev);
	int HandleSocketClosed(evutil_socket_t fd);
	int HandleSocketError(evutil_socket_t fd);
	int HandleSocketConnectToSuccess(evutil_socket_t fd);
	void HandleWorkEvent();
	void HandleHttpConnClose(struct evhttp_connection *http_conn);

	struct HttpRequestArg
	{
		NetService *ns;
		int64_t session_id;
	};

private:

	Mailbox *NewMailbox(int fd, E_CONN_TYPE type);
	Mailbox *GetMailboxByFd(int fd);
	Mailbox *GetMailboxByMailboxId(int64_t mailboxId);
	void CloseMailbox(Mailbox *pmb);
	void CloseMailboxByFd(int fd);
	void CloseMailboxByMailboxId(int64_t mailboxId);

	int SocketReadMessage(struct bufferevent *bev);
	void HandleWorldEvent();
	void HandleSendPluto();
	bool HttpRequest(const char *url, int64_t session_id, int request_type, const char *post_data, int post_data_len);
	struct evhttp_connection * GetHttpConnection(struct event_base *main_event, struct evdns_base *dns, const char *host, int port);

	int m_maxConn;
	struct event_base *m_mainEvent;
	struct event *m_workTimerEvent;
	struct event *m_tickTimerEvent;
	struct event *m_stdinEvent;
	struct evconnlistener *m_evconnlistener;

	std::map<int, Mailbox *> m_fds;
	std::map<int64_t, Mailbox *> m_mailboxs;
	std::list<Mailbox *> m_delMailboxs;
	std::set<Mailbox *> m_sendMailboxs;

	std::set<std::string> m_trustIpSet;
	EventPipe *m_net2worldPipe;
	EventPipe *m_world2netPipe;

	std::map<std::string, struct evhttp_connection *> m_httpConnMap; // "host:port" : conn
};

