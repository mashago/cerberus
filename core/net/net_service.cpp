
extern "C"
{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef WIN32
#include <io.h>  
#include <process.h>
#include <winsock2.h>
#include <conio.h>
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

#include <event2/event.h>
#include <event2/listener.h>
#include <event2/bufferevent.h>
#include <event2/buffer.h>
#include <event2/http.h>
}
#include <string>

#include "logger.h"
#include "util.h"
#include "net_service.h"
#include "event_pipe.h"
#include "pluto.h"
#include "mailbox.h"

enum READ_MSG_RESULT
{
	READ_MSG_ERROR 		= -1
,	READ_MSG_WAIT 		= 0 
,	READ_MSG_FINISH 	= 1 
};

static void listen_cb(struct evconnlistener *listener, evutil_socket_t fd, struct sockaddr *sa, int socklen, void *user_data);
static void read_cb(struct bufferevent *bev, void *user_data);
static void event_cb(struct bufferevent *bev, short event, void *user_data);
static void work_timer_cb(evutil_socket_t fd, short event, void *user_data);
static void tick_timer_cb(evutil_socket_t fd, short event, void *user_data);
static void stdin_cb(evutil_socket_t fd, short event, void *user_data);
static void http_conn_close_cb(struct evhttp_connection *http_conn, void *user_data);
static void http_done_cb(struct evhttp_request *http_request, void *user_data);


NetService::NetService() : m_maxConn(0), m_mainEvent(nullptr), m_workTimerEvent(nullptr), m_tickTimerEvent(nullptr), m_stdinEvent(nullptr), m_evconnlistener(nullptr)
{
}

NetService::~NetService()
{
}


int NetService::Init(const char *addr, unsigned int port, int maxConn, std::set<std::string> &trustIpSet, EventPipe *net2worldPipe, EventPipe *world2netPipe)
{
	m_maxConn = maxConn;
	m_trustIpSet = trustIpSet;

	// new event_base
	m_mainEvent = event_base_new();
	if (!m_mainEvent)
	{
		LOG_ERROR("event_base_new fail");
		return -1;
	}

	// listen
	if (port > 0 && !Listen(addr, port))
	{
		LOG_ERROR("listen fail");
		return -1;
	}

	// init work timer, for net_server handle logic
	m_workTimerEvent = event_new(m_mainEvent, -1, EV_PERSIST, work_timer_cb, this);
	struct timeval tv;
	tv.tv_sec = 0;
	// tv.tv_sec = 3;
	tv.tv_usec = 50 * 1000;
	if (event_add(m_workTimerEvent, &tv) != 0)
	{
		LOG_ERROR("add work timer fail");
		return -1;
	}

	// init tick timer, for world timer
	m_tickTimerEvent = event_new(m_mainEvent, -1, EV_PERSIST, tick_timer_cb, this);
	tv.tv_sec = 0;
	tv.tv_usec = 100 * 1000;
	if (event_add(m_tickTimerEvent, &tv) != 0)
	{
		LOG_ERROR("add tick timer fail");
		return -1;
	}

	// init stdin event
	// in win32, cannot add stdin fd into libevent
	// so have to create a timer to check keyboard input
	// good job, microsoft.
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
		return -1;
	}

	m_net2worldPipe = net2worldPipe;
	m_world2netPipe = world2netPipe;

	return 0;
}

int NetService::Dispatch()
{

	event_base_dispatch(m_mainEvent);

	if (m_workTimerEvent)
	{
		event_del(m_workTimerEvent);
		event_free(m_workTimerEvent);
		m_workTimerEvent = NULL;
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

int64_t NetService::ConnectTo(const char *addr, unsigned int port)
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
	bufferevent_enable(bev, EV_READ); // XXX consider set EV_PERSIST ?

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
	Mailbox *pmb = NewMailbox(fd, E_CONN_TYPE::CONN_TYPE_TRUST);
	if (!pmb)
	{
		LOG_ERROR("mailbox null fd=%d", fd);
		bufferevent_free(bev);
		return -1;
	}
	pmb->SetBEV(bev);

	return pmb->GetMailboxId();
}

bool NetService::Listen(const char *addr, unsigned int port)
{
	// 1. new event_base
	// 2. init listener
	// 3. set nonblock
	// 4. init timer

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
		return false;
	}

	// set nonblock
	evutil_socket_t listen_fd = evconnlistener_get_fd(m_evconnlistener);
	evutil_make_socket_nonblocking(listen_fd);

	return true;
}

////////////////// mainbox function start [

Mailbox * NetService::NewMailbox(int fd, E_CONN_TYPE connType)
{
	Mailbox *pmb = new Mailbox(connType);
	if (!pmb)
	{
		return nullptr;
	}

	pmb->SetFd(fd);

	auto iter = m_fds.lower_bound(fd);
	if (iter != m_fds.end() && iter->first == fd)
	{
		// still has old mailbox
		Mailbox *oldmb = iter->second;
		if (oldmb != pmb)
		{
			delete oldmb;
			iter->second = pmb;
		}
		LOG_WARN("has old mailbox fd=%d", fd);
	}
	else
	{
		// normal logic, insert new mailbox
		m_fds.insert(iter, std::make_pair(fd, pmb));
	}
	m_mailboxs[pmb->GetMailboxId()] = pmb;

	return pmb;
}

Mailbox *NetService::GetMailboxByFd(int fd)
{
	auto iter = m_fds.find(fd);
	if (iter == m_fds.end())
	{
		return nullptr;
	}
	return iter->second;
}

Mailbox *NetService::GetMailboxByMailboxId(int64_t mailboxId)
{
	auto iter = m_mailboxs.find(mailboxId);
	if (iter == m_mailboxs.end())
	{
		return nullptr;
	}
	return iter->second;
}

void NetService::CloseMailbox(Mailbox *pmb)
{
	if (pmb->GetBEV() != nullptr)
	{
		bufferevent_free(pmb->GetBEV());
		pmb->SetBEV(nullptr);
	}
	else
	{
		LOG_WARN("m_bev null %d", pmb->GetMailboxId());
	}

	// notice to world
	EventNodeDisconnect *node = new EventNodeDisconnect();
	node->mailboxId = pmb->GetMailboxId();
	SendEvent(node);

	// push to list, delete by tick
	pmb->SetDeleteFlag();
	m_fds.erase(pmb->GetFd());
	m_mailboxs.erase(pmb->GetMailboxId());
	m_delMailboxs.push_back(pmb);
	m_sendMailboxs.erase(pmb);
}

void NetService::CloseMailboxByFd(int fd)
{
	Mailbox *pmb = GetMailboxByFd(fd);
	if (pmb == nullptr)
	{
		LOG_WARN("mailbox null fd=%d", fd);
		return;
	}
	CloseMailbox(pmb);
}

void NetService::CloseMailboxByMailboxId(int64_t mailboxId)
{
	Mailbox *pmb = GetMailboxByMailboxId(mailboxId);
	if (pmb == nullptr)
	{
		LOG_WARN("mailbox null mailboxId=%ld", mailboxId);
		return;
	}
	CloseMailbox(pmb);
}

////////////////////// mainbox function end ]

void NetService::SendEvent(EventNode *node)
{
	m_net2worldPipe->Push(node);
}

int NetService::HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen)
{
	LOG_DEBUG("fd=%d", fd);

	// 1. check connection num
	// 2. check connection is valide
	// 3. set fd non-block
	// 4. accept clinet
	// 5. new mailbox
	// 6. send to world
	
	struct sockaddr_in *sin = (struct sockaddr_in *)sa;
	const char *clientHost = inet_ntoa(sin->sin_addr);
	uint16_t clientPort = ntohs(sin->sin_port);
	LOG_DEBUG("clientHost=%s clientPort=%d", clientHost, clientPort);

	// check connection num
	if (m_mailboxs.size() > m_maxConn)
	{
        LOG_WARN("connection is max fd=%d", fd);
		evutil_closesocket(fd);
		return -1;
	}

	// check connection is trust
	E_CONN_TYPE connType = E_CONN_TYPE::CONN_TYPE_UNTRUST;
	std::string ip(clientHost);

	auto iter = m_trustIpSet.find(ip);
	if (iter != m_trustIpSet.end())
	{
		connType = E_CONN_TYPE::CONN_TYPE_TRUST;
	}
	
	// TODO check connection is valid

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
	bufferevent_enable(bev, EV_READ); // XXX consider set EV_PERSIST ?
	
	// new mailbox
	Mailbox *pmb = NewMailbox(fd, connType);
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
	node->connType = connType;
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

	Mailbox *pmb = GetMailboxByFd(fd);
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

		if (input_len < MSGLEN_HEAD)
		{
			// data less then msg head
			return READ_MSG_WAIT;
		}

		// get msg head len
		char head[MSGLEN_HEAD];
		nLen= evbuffer_copyout(input, head, MSGLEN_HEAD);
		if (nLen < MSGLEN_HEAD)
		{
			return READ_MSG_WAIT;
		}

		// shift input data
		evbuffer_drain(input, nLen);

		// get msglen
		int msgLen = (int)ntohl(*(uint32_t *)head);
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
		memcpy(buffer, head, MSGLEN_HEAD);
		buffer += MSGLEN_HEAD;

		pu->SetRecvLen(MSGLEN_HEAD);
		nWanted = msgLen - MSGLEN_HEAD;
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


int NetService::HandleSocketClosed(evutil_socket_t fd)
{
	CloseMailboxByFd(fd);
	return 0;
}

int NetService::HandleSocketError(evutil_socket_t fd)
{
	CloseMailboxByFd(fd);
	return 0;
}

int NetService::HandleSocketConnectToSuccess(evutil_socket_t fd)
{
	Mailbox *pmb = GetMailboxByFd(fd);
	if (pmb == NULL)
	{
		LOG_WARN("mailbox null fd=%d", fd);
		return 0;
	}

	// send to world
	EventNodeConnectToSuccess *node = new EventNodeConnectToSuccess();
	node->mailboxId = pmb->GetMailboxId();
	SendEvent(node);

	return 0;
}

void NetService::HandleWorldEvent()
{
	const std::list<EventNode *> &node_list = m_world2netPipe->Pop();
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
				CloseMailboxByMailboxId(real_node.mailboxId);
				break;
			}
			case EVENT_TYPE::EVENT_TYPE_MSG:
			{
				// add pluto into mailbox, set not auto delete pluto from node
				const EventNodeMsg &real_node = (EventNodeMsg&)node;
				Pluto *pu = real_node.pu;
				int64_t mailboxId = pu->GetMailboxId();
				// LOG_DEBUG("mailboxId=%ld", mailboxId);
				Mailbox *pmb = GetMailboxByMailboxId(mailboxId);
				if (!pmb)
				{
					LOG_WARN("mail box null %ld", mailboxId);
					delete pu; // world new, net delete
					break;
				}
				pmb->PushSendPluto(pu);
				m_sendMailboxs.insert(pmb);
				break;
			}
			case EVENT_TYPE::EVENT_TYPE_CONNECT_TO_REQ:
			{
				const EventNodeConnectToReq &real_node = (EventNodeConnectToReq&)node;
				// LOG_DEBUG("ext=%ld", real_node.ext);
				// get a mailboxId, and send to world
				int64_t mailboxId = ConnectTo(real_node.ip, real_node.port);
				EventNodeConnectToRet *ret_node = new EventNodeConnectToRet();
				ret_node->ext = real_node.ext;
				ret_node->mailboxId = mailboxId;
				SendEvent(ret_node);

				break;
			}
			case EVENT_TYPE::EVENT_TYPE_HTTP_REQ:
			{
				const EventNodeHttpReq &real_node = (EventNodeHttpReq&)node;
				HttpRequest(real_node.url, real_node.session_id, real_node.request_type, real_node.post_data, real_node.post_data_len);
				break;
			}
			default:
				LOG_ERROR("cannot handle this node %d", node.type);
				break;
		}

		delete *iter; // world new, net delete
	}
}

void NetService::HandleSendPluto()
{
	// loop all mailbox, do send all
	std::list<Mailbox *> ls4del;
	for (auto iter = m_sendMailboxs.begin(); iter != m_sendMailboxs.end(); )
	{
		Mailbox *pmb = *iter;
		if (!pmb)
		{
			m_sendMailboxs.erase(iter++);	
			LOG_ERROR("mailbox nil");
			continue;
		}
		// LOG_DEBUG("mailboxId=%ld", pmb->GetMailboxId());

		int ret = pmb->SendAll();
		if (ret == -1)
		{
			// send error
			m_sendMailboxs.erase(iter++);	
			ls4del.push_back(pmb);
			LOG_ERROR("send error %ld", pmb->GetMailboxId());
			continue;
		}
		else if (ret == 1)
		{
			// send finish
			m_sendMailboxs.erase(iter++);	
			continue;
		}

		// send not finish, keep mailbox in set
		++iter;
	}

	// close error mailbox
	for (auto iter = ls4del.begin(); iter != ls4del.end(); iter++)
	{
		CloseMailbox(*iter);
	}
}

void NetService::HandleWorkEvent()
{
	// 1. handle world event
	// 2. handle send pluto
	// 3. delete mailbox

	// handle world event
	HandleWorldEvent();

	// handle send pluto
	HandleSendPluto();

	// delete mailbox
	ClearContainer(m_delMailboxs);
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
		if (request_type == 1)
		{
			evhttp_make_request(http_conn, http_request, EVHTTP_REQ_GET, path);
		}
		else if (request_type == 2)
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
		ns->HandleSocketConnectToSuccess(fd);
	}
	else
	{
		LOG_ERROR("??????? unknow event fd=%d event=%d errno=%d", fd, event, errno);
	}
}

static void work_timer_cb(evutil_socket_t fd, short event, void *user_data)
{
	NetService *ns = (NetService *)user_data;
	ns->HandleWorkEvent();
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
			}

            putch(nInput);

            if (cInput == '\r')
            {
                cInput = '\n';
                putch(cInput);
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
	char buffer[MAX_BUFFER+1] = {0};
	int len = read(fd, buffer, MAX_BUFFER+1);
	if (len == 0)
	{
		// EOF
		return;
	}

	if (len > MAX_BUFFER)
	{
		LOG_WARN("stdin buffer too big");
		return;
	}

	if (len < 0)
	{
		LOG_ERROR("read stdin fail");
		return;
	}

	// trim /n
	while (len >= 1 && buffer[len-1] == '\n')
	{
		buffer[len-1] = '\0';
		len -= 1;
	}

	if (len == 0)
	{
		return;
	}

	NetService *ns = (NetService *)user_data;

	char *ptr = new char[len+1];
	memcpy(ptr, buffer, len+1);

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
