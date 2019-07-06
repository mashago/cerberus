
#pragma once

extern "C"
{
#include <stdint.h>
#ifdef WIN32
#include <winsock2.h>
#else
#include <unistd.h>
#include <netinet/in.h>
#endif
#include <event2/util.h>
}

#include <string>
#include <set>
#include <map>
#include <list>

struct event_base;
struct event;
struct bufferevent;
struct evconnlistener;
struct evdns_base;
struct evhttp_connection;

class Pluto;
class Mailbox;
class MailboxMgr;
class Listener;
class EventPipe;
struct EventNode;

class NetService
{
public:
	NetService();
	~NetService();

	bool Init(bool isDaemon, EventPipe *inputPipe, EventPipe *outputPipe);
	int Dispatch();

	// return >= 0 as listenId, < 0 as error
	int64_t Listen(const char *addr, unsigned int port);
	// return >= 0 as mailboxId, < 0 as error
	int64_t Connect(const char *addr, unsigned int port);

	void SendEvent(EventNode *node);
	void SendConnectCloseEvent(int64_t mailboxId);

	int HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen);
	int HandleSocketRead(struct bufferevent *bev);
	int HandleSocketClosed(evutil_socket_t fd);
	int HandleSocketError(evutil_socket_t fd);
	int HandleSocketConnectSuccess(evutil_socket_t fd);
	void HandleMainLoop();
	void HandleHttpConnClose(struct evhttp_connection *http_conn);

	struct HttpRequestArg
	{
		NetService *ns;
		int64_t session_id;
	};

private:
	int SocketReadMessage(struct bufferevent *bev);
	void CloseMailbox(Mailbox *pmb);
	void HandleWorldEvent();
	bool HttpRequest(const char *url, int64_t session_id, int request_type, const char *post_data, int post_data_len);
	struct evhttp_connection * GetHttpConnection(struct event_base *main_event, struct evdns_base *dns, const char *host, int port);

	struct event_base *m_mainEvent;
	struct event *m_mainLoopEvent;
	struct event *m_tickTimerEvent;
	struct event *m_stdinEvent;
	struct evconnlistener *m_evconnlistener;

	EventPipe *m_inputPipe;
	EventPipe *m_outputPipe;

	MailboxMgr *m_mailboxMgr;
	std::map<int, Listener *> m_listenerFds;
	std::map<int64_t, Listener *> m_listeners;
	std::map<int64_t, int64_t> m_connectSessions;

	std::map<std::string, struct evhttp_connection *> m_httpConnMap; // "host:port" : conn
};

