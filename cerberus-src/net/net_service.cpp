
extern "C"
{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef WIN32
#include <io.h>  
#include <conio.h>
#else
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#endif
#include <time.h>
#include <errno.h>

#include <event2/event.h>
#include <event2/listener.h>
#include <event2/bufferevent.h>
#include <event2/buffer.h>
#include <event2/http.h>
}

#include "common.h"
#include "logger.h"
#include "util.h"
#include "event_pipe.h"
#include "pluto.h"
#include "mailbox.h"
#include "mailbox_mgr.h"
#include "listener.h"
#include "net_service.h"

enum READ_MSG_RESULT
{
	READ_MSG_ERROR 		= -1
,	READ_MSG_WAIT 		= 0 
,	READ_MSG_FINISH 	= 1 
};

static void listen_cb(struct evconnlistener *listener, evutil_socket_t fd, struct sockaddr *sa, int socklen, void *user_data);
static void read_cb(struct bufferevent *bev, void *user_data);
static void event_cb(struct bufferevent *bev, short event, void *user_data);
static void main_loop_cb(evutil_socket_t fd, short event, void *user_data);
static void tick_timer_cb(evutil_socket_t fd, short event, void *user_data);
static void stdin_cb(evutil_socket_t fd, short event, void *user_data);
static void http_conn_close_cb(struct evhttp_connection *http_conn, void *user_data);
static void http_done_cb(struct evhttp_request *http_request, void *user_data);


NetService::NetService() : 
	m_mainEvent(nullptr),
	m_mainLoopEvent(nullptr),
	m_tickTimerEvent(nullptr),
	m_stdinEvent(nullptr),
	m_evconnlistener(nullptr),
	m_inputPipe(nullptr),
	m_outputPipe(nullptr)
{
}

NetService::~NetService()
{
}


bool NetService::Init(bool isDaemon, EventPipe *inputPipe, EventPipe *outputPipe)
{
	// new event_base
	m_mainEvent = event_base_new();
	if (!m_mainEvent)
	{
		LOG_ERROR("event_base_new fail");
		return false;
	}

	// init work timer, for net_service handle logic
	m_mainLoopEvent = event_new(m_mainEvent, -1, EV_PERSIST, main_loop_cb, this);
	struct timeval tv;
	tv.tv_sec = 0;
	tv.tv_usec = 50 * 1000;
	if (event_add(m_mainLoopEvent, &tv) != 0)
	{
		LOG_ERROR("add work timer fail");
		return false;
	}

	// init tick timer, for world timer
	m_tickTimerEvent = event_new(m_mainEvent, -1, EV_PERSIST, tick_timer_cb, this);
	tv.tv_sec = 0;
	tv.tv_usec = 100 * 1000;
	if (event_add(m_tickTimerEvent, &tv) != 0)
	{
		LOG_ERROR("add tick timer fail");
		return false;
	}

	// init stdin event if not daemon
	// in win32, cannot add stdin fd into libevent
	// so have to create a timer to check keyboard input
	// good job, microsoft.
	if (!isDaemon)
	{
		struct timeval *ptr = NULL;
#ifdef WIN32
		m_stdinEvent = event_new(m_mainEvent, -1, EV_PERSIST, stdin_cb, this);
		tv.tv_sec = 0;
		tv.tv_usec = 100;
		ptr = &tv;
#else
		m_stdinEvent = event_new(m_mainEvent, STDIN_FILENO, EV_READ | EV_PERSIST, stdin_cb, this);
#endif
		if (event_add(m_stdinEvent, ptr) != 0)
		{
			LOG_ERROR("add stdin event fail");
			return false;
		}
	}

	m_inputPipe = inputPipe;
	m_outputPipe = outputPipe;
	m_mailboxMgr = new MailboxMgr();

	return true;
}

int NetService::Dispatch()
{

	event_base_dispatch(m_mainEvent);

	if (m_mainLoopEvent)
	{
		event_del(m_mainLoopEvent);
		event_free(m_mainLoopEvent);
		m_mainLoopEvent = NULL;
	}

	if (m_tickTimerEvent)
	{
		event_del(m_tickTimerEvent);
		event_free(m_tickTimerEvent);
		m_tickTimerEvent = NULL;
	}

	if (m_stdinEvent)
	{
		event_del(m_stdinEvent);
		event_free(m_stdinEvent);
		m_stdinEvent = NULL;
	}

	event_base_free(m_mainEvent);

	return 0;
}

int64_t NetService::Listen(const char *addr, unsigned int port)
{
	// init listener
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_family = PF_INET;
	sin.sin_addr.s_addr = inet_addr(addr);
	sin.sin_port = htons(port);

	m_evconnlistener = evconnlistener_new_bind(m_mainEvent, listen_cb, (void *)this, LEV_OPT_REUSEABLE|LEV_OPT_CLOSE_ON_FREE, -1, (struct sockaddr *)&sin, sizeof(sin));
	if (!m_evconnlistener)
	{
		LOG_ERROR("new bind fail");
		return -1;
	}

	// set nonblock
	evutil_socket_t fd = evconnlistener_get_fd(m_evconnlistener);
	evutil_make_socket_nonblocking(fd);

	Listener *pl = new Listener(fd);
	m_listenerFds[fd] = pl;
	m_listeners[pl->GetListenId()] = pl;

	return pl->GetListenId();
}

int64_t NetService::Connect(const char *addr, unsigned int port)
{
	// 1. init a sin
	// 2. init buffer socket
	// 3. set nonblock
	// 4. connect
	// 5. new mailbox

	// init a sin
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_family = PF_INET;
	sin.sin_addr.s_addr = inet_addr(addr);
	sin.sin_port = htons(port);

	// init buffer socket
	struct bufferevent *bev = bufferevent_socket_new(m_mainEvent, -1, BEV_OPT_CLOSE_ON_FREE); // | BEV_OPT_DEFER_CALLBACKS);
	if (!bev)
	{
		LOG_ERROR("bufferevent new fail");
		return -1;
	}
	bufferevent_setcb(bev, read_cb, NULL, event_cb, (void *)this);
	bufferevent_enable(bev, EV_READ);

	// non-block connect
	int ret = bufferevent_socket_connect(bev, (struct sockaddr *)&sin, sizeof(sin));
	if (ret < 0)
	{
		LOG_ERROR("bufferevent connect fail ret=%d", ret);
		bufferevent_free(bev);
		return -1;
	}

	evutil_socket_t fd = bufferevent_getfd(bev);
	LOG_DEBUG("fd=%d", fd);
	// set nonblock
	// evutil_make_socket_nonblocking(fd); // already set non-block in bufferevent_socket_connect()

	// new mailbox
	Mailbox *pmb = m_mailboxMgr->NewMailbox(fd);
	if (!pmb)
	{
		LOG_ERROR("mailbox null fd=%d", fd);
		bufferevent_free(bev);
		return -1;
	}
	pmb->SetBEV(bev);

	return pmb->GetMailboxId();
}

void NetService::SendEvent(EventNode *node)
{
	m_outputPipe->Push(node);
}

void NetService::SendConnectCloseEvent(int64_t mailboxId)
{
	auto iter = m_connectSessions.find(mailboxId);
	if (iter == m_connectSessions.end())
	{
		// notice to world
		EventNodeDisconnect *node = new EventNodeDisconnect();
		node->mailboxId = mailboxId;
		SendEvent(node);
	}
	else
	{
		EventNodeConnectRet *node = new EventNodeConnectRet();
		node->session_id = iter->second;
		node->mailboxId = 0;
		SendEvent(node);
		m_connectSessions.erase(iter);
	}
}

int NetService::HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen)
{
	LOG_DEBUG("fd=%d", fd);

	// connection info
	struct sockaddr_in *sin = (struct sockaddr_in *)sa;
	const char *clientHost = inet_ntoa(sin->sin_addr);
	uint16_t clientPort = ntohs(sin->sin_port);
	LOG_DEBUG("clientHost=%s clientPort=%d", clientHost, clientPort);

	// set fd non-block
	evutil_make_socket_nonblocking(fd);

	// accept client
	// init buffer socket
	struct bufferevent *bev = bufferevent_socket_new(m_mainEvent, fd, BEV_OPT_CLOSE_ON_FREE); // | BEV_OPT_DEFER_CALLBACKS);
	if (!bev)
	{
		LOG_ERROR("bufferevent new fail");
		evutil_closesocket(fd);
		return -1;
	}
	bufferevent_setcb(bev, read_cb, NULL, event_cb, (void *)this);
	bufferevent_enable(bev, EV_READ);
	
	// new mailbox
	Mailbox *pmb = m_mailboxMgr->NewMailbox(fd);
	if (!pmb)
	{
		LOG_ERROR("mailbox null fd=%d", fd);
		bufferevent_free(bev);
		return -1;
	}
	pmb->SetBEV(bev);

	// send to world
	EventNodeNewConnection *node = new EventNodeNewConnection();
	node->mailboxId = pmb->GetMailboxId();
	snprintf(node->ip, sizeof(node->ip), "%s", clientHost);
	node->port = clientPort;
	SendEvent(node);

	return 0;
}

int NetService::HandleSocketRead(struct bufferevent *bev)
{
	// loop to handle read data
	
	// evutil_socket_t fd = bufferevent_getfd(bev);
	// LOG_DEBUG("fd=%d", fd);
	int ret = READ_MSG_WAIT;
	do
	{
		ret = SocketReadMessage(bev);
	} 
	while (ret == READ_MSG_FINISH);

	return 0;
}

int NetService::SocketReadMessage(struct bufferevent *bev)
{
	evutil_socket_t fd = bufferevent_getfd(bev);

	Mailbox *pmb = m_mailboxMgr->GetMailboxByFd(fd);
	if (pmb == nullptr)
	{
		return READ_MSG_ERROR;
	}

	// 1. get input evbuffer and length
	// 2. check if has pluto in mailbox
	// 3. copy to pluto buffer
	// 4. if read msg finish, send pluto to world, and clean mailbox pluto

	// get input evbuffer and length
	struct evbuffer *input = bufferevent_get_input(bev);
	const size_t input_len = evbuffer_get_length(input);

	// LOG_DEBUG("input_len=%lu", input_len);
	if (input_len == 0)
	{
		return READ_MSG_WAIT;
	}

	char *buffer = nullptr;
	int nWanted = 0;
	ev_ssize_t nLen = 0;

	Pluto *pu = pmb->GetRecvPluto();
	if (pu == nullptr)
	{
		// no pluto in mailbox

		if (input_len < MSGLEN_SIZE)
		{
			// data less then msg size
			return READ_MSG_WAIT;
		}

		// get msg head len
		char head[MSGLEN_SIZE];
		nLen= evbuffer_copyout(input, head, MSGLEN_SIZE);
		if (nLen < MSGLEN_SIZE)
		{
			return READ_MSG_WAIT;
		}

		// shift input data
		evbuffer_drain(input, nLen);

		// get msglen
		int msgLen = *(int *)(head);
		if (msgLen > MSGLEN_MAX)
		{
			// msg len over size, should kick this connection
			LOG_WARN("msg too long fd=%d msgLen=%d", fd, msgLen);
			CloseMailbox(pmb);
			return READ_MSG_ERROR;
		}

		// new a pluto
		pu = new Pluto(msgLen); // net new, world delete
		pmb->SetRecvPluto(pu);

		// copy msghead to buffer
		buffer = pu->GetBuffer();
		memcpy(buffer, head, MSGLEN_SIZE);
		buffer += MSGLEN_SIZE;

		pu->SetRecvLen(MSGLEN_SIZE);
		nWanted = msgLen - MSGLEN_SIZE;
	}

	else
	{
		// already has pluto in mailbox
		buffer = pu->GetBuffer() + pu->GetRecvLen();
		nWanted = pu->GetMsgLen() - pu->GetRecvLen();
	}

	// copy remain data to buffer
	nLen = evbuffer_copyout(input, buffer, nWanted);
	if (nLen <= 0)
	{
		// no more data
		return READ_MSG_WAIT;
	}
	evbuffer_drain(input, nLen);

	if (nLen != nWanted)
	{
		// data not recv finish
		// update recv len
		pu->SetRecvLen(pu->GetRecvLen() + nLen);
		return READ_MSG_WAIT;
	}

	// get a full msg
	// add into recv msg list
	pu->SetRecvLen(pu->GetMsgLen());
	pu->SetMailboxId(pmb->GetMailboxId());

	// send to world
	EventNodeMsg *node = new EventNodeMsg();
	node->pu = pu;
	SendEvent(node);

	// clean mailbox pluto
	pmb->SetRecvPluto(nullptr);

	return READ_MSG_FINISH;
}

void NetService::CloseMailbox(Mailbox *pmb)
{
	m_mailboxMgr->CloseMailbox(pmb);
	SendConnectCloseEvent(pmb->GetMailboxId());
}

int NetService::HandleSocketClosed(evutil_socket_t fd)
{
	Mailbox *pmb = m_mailboxMgr->GetMailboxByFd(fd);
	if (pmb)
	{
		CloseMailbox(pmb);
	}
	return 0;
}

int NetService::HandleSocketError(evutil_socket_t fd)
{
	Mailbox *pmb = m_mailboxMgr->GetMailboxByFd(fd);
	if (pmb)
	{
		CloseMailbox(pmb);
	}
	return 0;
}

int NetService::HandleSocketConnectSuccess(evutil_socket_t fd)
{
	Mailbox *pmb = m_mailboxMgr->GetMailboxByFd(fd);
	if (pmb == nullptr)
	{
		LOG_WARN("mailbox null fd=%d", fd);
		return 0;
	}
	auto iter = m_connectSessions.find(pmb->GetMailboxId());
	if (iter == m_connectSessions.end())
	{
		LOG_ERROR("session nil fd=%d", fd);
		return 0;
	}

	EventNodeConnectRet *ret_node = new EventNodeConnectRet();
	ret_node->session_id = iter->second;
	ret_node->mailboxId = pmb->GetMailboxId();
	SendEvent(ret_node);
	m_connectSessions.erase(iter);

	return 0;
}

void NetService::HandleWorldEvent()
{
	const std::list<EventNode *> &node_list = m_inputPipe->Pop();
	for (auto iter = node_list.begin(); iter != node_list.end(); iter++)
	{
		const EventNode &node = **iter;
		// LOG_DEBUG("node.type=%d", node.type);
		switch (node.type)
		{
			case EVENT_TYPE::EVENT_TYPE_DISCONNECT:
			{
				const EventNodeDisconnect &real_node = (EventNodeDisconnect&)node;
				// LOG_DEBUG("mailboxId=%ld", real_node.mailboxId);
				Mailbox *pmb = m_mailboxMgr->GetMailboxByMailboxId(real_node.mailboxId);
				if (pmb)
				{
					CloseMailbox(pmb);
				}
				break;
			}
			case EVENT_TYPE::EVENT_TYPE_MSG:
			{
				// add pluto into mailbox, set not auto delete pluto from node
				const EventNodeMsg &real_node = (EventNodeMsg&)node;
				int64_t mailboxId = real_node.pu->GetMailboxId();
				// LOG_DEBUG("mailboxId=%ld", mailboxId);
				Mailbox *pmb = m_mailboxMgr->GetMailboxByMailboxId(mailboxId);
				if (!pmb)
				{
					LOG_WARN("mail box null %ld", mailboxId);
					delete real_node.pu; // world new, net delete
					break;
				}
				pmb->Push(real_node.pu);
				m_mailboxMgr->MarkSend(pmb);
				break;
			}
			case EVENT_TYPE::EVENT_TYPE_CONNECT_REQ:
			{
				const EventNodeConnectReq &real_node = (EventNodeConnectReq&)node;
				// send event until connection success or error rather than send right now except Connect error
				int64_t mailboxId = Connect(real_node.ip, real_node.port);
				if (mailboxId == -1)
				{
					EventNodeConnectRet *ret_node = new EventNodeConnectRet();
					ret_node->session_id = real_node.session_id;
					ret_node->mailboxId = mailboxId;
					SendEvent(ret_node);
					break;
				}
				m_connectSessions[mailboxId] = real_node.session_id;
				break;
			}
			case EVENT_TYPE::EVENT_TYPE_HTTP_REQ:
			{
				const EventNodeHttpReq &real_node = (EventNodeHttpReq&)node;
				HttpRequest(real_node.url, real_node.session_id, real_node.request_type, real_node.post_data, real_node.post_data_len);
				break;
			}
			case EVENT_TYPE::EVENT_TYPE_LISTEN_REQ:
			{
				const EventNodeListenReq &real_node = (EventNodeListenReq&)node;
				int64_t listenId = Listen(real_node.ip, real_node.port);
				EventNodeListenRet *node = new EventNodeListenRet();
				node->listenId = listenId;
				node->session_id = real_node.session_id;
				SendEvent(node);

				break;
			}
			default:
				LOG_ERROR("cannot handle this node %d", node.type);
				break;
		}

		delete *iter; // world new, net delete
	}
}

void NetService::HandleMainLoop()
{
	// 1. handle world event
	// 2. handle send pluto

	// handle world event
	HandleWorldEvent();

	// handle send pluto
	m_mailboxMgr->Send();
}

void NetService::HandleHttpConnClose(struct evhttp_connection *http_conn)
{
	for (auto iter = m_httpConnMap.begin(); iter != m_httpConnMap.end(); ++iter)
	{
		if (iter->second == http_conn)
		{
			m_httpConnMap.erase(iter);
			break;
		}
	}
}

enum HTTP_REQUEST_TYPE
{
	HTTP_REQUEST_GET 	= 1,
	HTTP_REQUEST_POST 	= 2,
};

bool NetService::HttpRequest(const char *url, int64_t session_id, int request_type, const char *post_data, int post_data_len)
{

	// 1. init uri, host, port, path
	// 2. new dns
	// 3. new connection
	// 4. new request

	struct evhttp_uri *uri = NULL;
	do
	{
		// 1. init uri, host, port, path
		uri = evhttp_uri_parse(url);
		if (!uri)
		{
			LOG_ERROR("evhttp_uri_parse fail");
			break;
		}

		const char *host = evhttp_uri_get_host(uri);
		if (!host)
		{
			LOG_ERROR("evhttp_uri_get_host fail");
			break;
		}
		
		int port = evhttp_uri_get_port(uri);
		if (port == -1)
		{
			port = 80;
		}

		const char *path = evhttp_uri_get_path(uri);
		if (!path || strlen(path) == 0)
		{
			path = "/";
		}

		// 3. new connection
		struct evhttp_connection *http_conn = GetHttpConnection(m_mainEvent, NULL, host, port);
		if (!http_conn)
		{
			LOG_ERROR("create_connection fail");
			break;
		}

		// 4. new request
		struct NetService::HttpRequestArg *arg = new NetService::HttpRequestArg;
		arg->ns = this;
		arg->session_id = session_id;
		struct evhttp_request *http_request = evhttp_request_new(http_done_cb, (void *)arg);
		evhttp_add_header(evhttp_request_get_output_headers(http_request), "Host", host);
		if (request_type == HTTP_REQUEST_GET)
		{
			evhttp_make_request(http_conn, http_request, EVHTTP_REQ_GET, path);
		}
		else if (request_type == HTTP_REQUEST_POST)
		{
			evbuffer_add(evhttp_request_get_output_buffer(http_request), post_data, post_data_len);
			evhttp_make_request(http_conn, http_request, EVHTTP_REQ_POST, path);
		}

	}
	while (false);

	if (uri)
	{
		evhttp_uri_free(uri);
	}

	return true;
}

static std::string get_http_conn_key(const char *host, int port)
{
	std::string key(host);
	key.append(":");
	key.append(std::to_string(port));
	return key;
}

struct evhttp_connection * NetService::GetHttpConnection(struct event_base *main_event, struct evdns_base *dns, const char *host, int port)
{
	std::string key = get_http_conn_key(host, port);
	auto iter = m_httpConnMap.find(key);
	if (iter != m_httpConnMap.end())
	{
		LOG_DEBUG("create_connection: use old connection");
		return iter->second;
	}

	LOG_DEBUG("create_connection: new connection");
	struct evhttp_connection *http_conn = evhttp_connection_base_new(main_event, dns, host, port);
	if (!http_conn)
	{
		LOG_ERROR("evhttp_connection_base_new fail");
		return NULL;
	}
	evhttp_connection_set_timeout(http_conn, 600);
	evhttp_connection_set_closecb(http_conn, http_conn_close_cb, (void *)this);

	m_httpConnMap[key] = http_conn;

	return http_conn;
}

////////// callback start [

static void listen_cb(struct evconnlistener *listener, evutil_socket_t fd, struct sockaddr *sa, int socklen, void *user_data)
{
	// handle new client connect event
	NetService *ns = (NetService *)user_data;
	ns->HandleNewConnection(fd, sa, socklen);
}

static void read_cb(struct bufferevent *bev, void *user_data)
{
	// handle read event
	NetService *ns = (NetService *)user_data;
	ns->HandleSocketRead(bev);
}

static void event_cb(struct bufferevent *bev, short event, void *user_data)
{
	// LOG_DEBUG("******* event=%d", event);
	// handle other event
	NetService *ns = (NetService *)user_data;
	evutil_socket_t fd = bufferevent_getfd(bev);

	if (event & BEV_EVENT_EOF)
	{
		LOG_DEBUG("####### event eof fd=%d", fd);
		ns->HandleSocketClosed(fd);
	}
	else if (event & BEV_EVENT_ERROR)
	{
		LOG_ERROR("!!!!!!! event error fd=%d errno=%d", fd, errno);
		ns->HandleSocketError(fd);
	}
	else if (event & BEV_EVENT_CONNECTED)
	{
		LOG_DEBUG("@@@@@@@ event connected %d", fd);
		ns->HandleSocketConnectSuccess(fd);
	}
	else
	{
		LOG_ERROR("??????? unknow event fd=%d event=%d errno=%d", fd, event, errno);
		ns->HandleSocketError(fd);
	}
}

static void main_loop_cb(evutil_socket_t fd, short event, void *user_data)
{
	NetService *ns = (NetService *)user_data;
	ns->HandleMainLoop();
}

// for add timer
static void tick_timer_cb(evutil_socket_t fd, short event, void *user_data)
{
	// do nothing in net, just send to world
	NetService *ns = (NetService *)user_data;
	EventNodeTimer *node = new EventNodeTimer();
	ns->SendEvent(node);
}

#ifdef WIN32
// http://www.cnblogs.com/kingstarer/p/6629562.html
static void stdin_cb(evutil_socket_t fd, short event, void *user_data)
{
	static bool bLineEnd = false;
	static std::string buffer = "";
	
	// check keyboard hit
	if (_kbhit())
	{
		char cInput = EOF;
		do
		{
			// get input char, _getch() can get char without enter press
			int nInput = (char) _getch();
			cInput = (char) nInput;

			if (nInput >= 32 && nInput <= 126)
			{
				char tmp[2];
				tmp[0] = cInput;
				tmp[1] = '\0';
				buffer.append(tmp);
				_putch(nInput);
			}
			else if (nInput == 8)
			{
				// backspace
				if (buffer.size() > 0)
				{
					buffer.pop_back();
					_putch(nInput);
					_putch(' ');
					_putch(nInput);
				}
			}
			else
			{
				_putch(nInput);
			}


			if (cInput == '\r')
			{
				cInput = '\n';
				_putch(cInput);
				// buffer.append("\n");
				bLineEnd = true;
				break;
			}
		}
		while (_kbhit());
	}

	if (bLineEnd)
	{
		// printf("buffer=%s", buffer.c_str());
		// struct evbuffer *output = bufferevent_get_output(bev);
		// evbuffer_add(output, buffer.c_str(), buffer.size());

		NetService *ns = (NetService *)user_data;

		int size = buffer.size();
		char *ptr = new char[size+1];
		memcpy(ptr, buffer.c_str(), size);
		ptr[size] = '\0';

		EventNodeStdin *node = new EventNodeStdin();
		node->buffer = ptr;
		ns->SendEvent(node);

		buffer = "";
		bLineEnd = false;
	}
}
#else
static void stdin_cb(evutil_socket_t fd, short event, void *user_data)
{
	const int MAX_BUFFER = 1024;
	char *ptr = new char[MAX_BUFFER+1]();
	bool bSuccess = true;

	do
	{
		int len = read(fd, ptr, MAX_BUFFER);
		if (len == 0)
		{
			// EOF
			bSuccess = false;
			break;
		}

		if (len >= MAX_BUFFER)
		{
			LOG_WARN("stdin buffer too big");
			bSuccess = false;
			break;
		}

		if (len < 0)
		{
			LOG_ERROR("read stdin fail");
			bSuccess = false;
			break;
		}

		// trim /n
		while (len >= 1 && ptr[len-1] == '\n')
		{
			ptr[len-1] = '\0';
			len -= 1;
		}

		if (len == 0)
		{
			bSuccess = false;
			break;
		}

	} while(false);

	if (!bSuccess)
	{
		delete [] ptr;
		return;
	}

	NetService *ns = (NetService *)user_data;
	EventNodeStdin *node = new EventNodeStdin();
	node->buffer = ptr;
	ns->SendEvent(node);
}
#endif

static void http_conn_close_cb(struct evhttp_connection *http_conn, void *user_data)
{
	LOG_DEBUG("******* http_conn_close_callback *******");

	NetService *ns = (NetService *)user_data;
	ns->HandleHttpConnClose(http_conn);
}

static void http_done_cb(struct evhttp_request *http_request, void *user_data)
{
	struct NetService::HttpRequestArg *arg = (struct NetService::HttpRequestArg *)user_data;
	NetService *ns = arg->ns;
	EventNodeHttpRsp *node = new EventNodeHttpRsp;
	do
	{
		node->session_id = arg->session_id;
		if (!http_request)
		{
			node->response_code = -1;
			break;
		}

		node->response_code = evhttp_request_get_response_code(http_request);
		
		struct evbuffer *input_buffer = evhttp_request_get_input_buffer(http_request);
		size_t input_len = evbuffer_get_length(input_buffer);
		LOG_DEBUG("input_len=%d", input_len);

		if (input_len > 0)
		{
			char *content = new char[input_len];
			
			int n = evbuffer_copyout(input_buffer, content, input_len);
			evbuffer_drain(input_buffer, n);
			node->content = content;
			node->content_len = input_len;
			// LOG_DEBUG("http_done_cb: content=%s", content);
		}
	}
	while (false);

	ns->SendEvent(node);
	delete arg;
}

////////// callback end ]
