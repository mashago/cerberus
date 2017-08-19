
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

	void CloseMailboxByFd(int fd);
	void CloseMailbox(int64_t mailboxId);
	void CloseMailbox(Mailbox *pmb);

	void RemoveHttpConn(struct evhttp_connection *http_conn);
	bool HttpRequest(const char *url, int64_t session_id, int request_type, const char *post_data, int post_data_len);

private:
	bool Listen(const char *addr, unsigned int port);
	Mailbox * NewMailbox(int fd, E_CONN_TYPE type);
	struct evhttp_connection * GetHttpConnection(struct event_base *main_event, struct evdns_base *dns, const char *host, int port);

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

	std::map<std::string, struct evhttp_connection *> m_httpConnMap; // "host:port" : conn
};

struct HttpRequestArg
{
	NetService *ns;
	int64_t session_id;
};

