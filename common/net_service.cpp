
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
#include "logger.h"
#include "common.h"
#include "util.h"
#include "net_service.h"
#include "timermgr.h"

static void listen_cb(struct evconnlistener *listener, evutil_socket_t fd, struct sockaddr *sa, int socklen, void *user_data);
static void read_cb(struct bufferevent *bev, void *user_data);
static void event_cb(struct bufferevent *bev, short event, void *user_data);
static void tick_cb(evutil_socket_t fd, short event, void *user_data);
static void timer_cb(evutil_socket_t fd, short event, void *user_data);


NetService::NetService() : m_mainEvent(nullptr), m_tickEvent(nullptr), m_timerEvent(nullptr), m_evconnlistener(nullptr), m_world(nullptr)
{
}

NetService::~NetService()
{
}


int NetService::Init(const char *addr, unsigned int port)
{
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

	// init tick timer
	m_tickEvent = event_new(m_mainEvent, -1, EV_PERSIST, tick_cb, this);
	struct timeval tv;
	tv.tv_sec = 0;
	// tv.tv_sec = 3;
	tv.tv_usec = 50 * 1000;
	if (event_add(m_tickEvent, &tv) != 0)
	{
		LOG_ERROR("add tick timer fail");
		return -1;
	}

	// init timer
	auto addTimer = [&]()
	{
		int wait_sec = 1;
		int wait_usec = 0;
		m_timerEvent = event_new(m_mainEvent, -1, EV_PERSIST, timer_cb, this);
		struct timeval tv;
		tv.tv_sec = wait_sec;
		tv.tv_usec = wait_usec;
		if (event_add(m_timerEvent, &tv) != 0)
		{
			LOG_ERROR("add normal timer fail");
			return false;
		}
		return true;
	};
	if (!addTimer())
	{
		return -1;
	}

	return 0;
}

int NetService::Service()
{

	event_base_dispatch(m_mainEvent);

	if (m_tickEvent)
	{
		event_del(m_tickEvent);
		event_free(m_tickEvent);
		m_tickEvent = NULL;
	}

	event_base_free(m_mainEvent);

	return 0;
}

int NetService::ConnectTo(const char *addr, unsigned int port)
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
	struct bufferevent *bev = bufferevent_socket_new(m_mainEvent, -1, BEV_OPT_CLOSE_ON_FREE | BEV_OPT_DEFER_CALLBACKS);
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
		m_fds.erase(fd);
		return -1;
	}
	pmb->m_bev = bev;

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

Mailbox *NetService::GetMailbox(int fd)
{
	auto iter = m_fds.find(fd);
	if (iter == m_fds.end())
	{
		return nullptr;
	}
	return iter->second;
}

void NetService::SetWorld(World *world)
{
	m_world = world;
}

World *NetService::GetWorld()
{
	return m_world;
}


int NetService::HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen)
{
	LOG_DEBUG("fd=%d", fd);

	// 1. check connection num
	// 2. check connection is valide
	// 3. set fd non-block
	// 4. accept clinet
	
	struct sockaddr_in *sin = (struct sockaddr_in *)sa;

	const char *clientHost = inet_ntoa(sin->sin_addr);
	uint16_t clientPort = ntohs(sin->sin_port);
	LOG_DEBUG("clientHost=%s clientPort=%d", clientHost, clientPort);

	// check connection num
	// TODO

	// check connection is server or client
	E_CONN_TYPE type = E_CONN_TYPE::CONN_TYPE_TRUST; // XXX
	
	// check connection is valide
	// TODO

	// set fd non-block
	evutil_make_socket_nonblocking(fd);

	// accept client

	// init buffer socket
	struct bufferevent *bev = bufferevent_socket_new(m_mainEvent, fd, BEV_OPT_CLOSE_ON_FREE | BEV_OPT_DEFER_CALLBACKS);
	if (!bev)
	{
        LOG_ERROR("bufferevent new fail");
		evutil_closesocket(fd);
		return -1;
	}
	bufferevent_setcb(bev, read_cb, NULL, event_cb, (void *)this);
	bufferevent_enable(bev, EV_READ); // XXX consider set EV_PERSIST ?
	
	// new mailbox
	Mailbox *pmb = NewMailbox(fd, type);
	if (!pmb)
	{
		LOG_ERROR("mailbox null fd=%d", fd);
		bufferevent_free(bev);
		m_fds.erase(fd);
		return -1;
	}
	pmb->m_bev = bev;

	m_world->HandleNewConnection(pmb);

	return 0;
}

Mailbox * NetService::NewMailbox(int fd, E_CONN_TYPE type)
{
	Mailbox *pmb = new Mailbox(type);
	if (!pmb)
	{
		return nullptr;
	}

	pmb->SetMailboxId(fd);

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

	return pmb;
}

enum READ_MSG_RESULT
{
	READ_MSG_ERROR 		= -1
,	READ_MSG_WAIT 		= 0 
,	READ_MSG_FINISH 	= 1 
};

int NetService::HandleSocketReadEvent(struct bufferevent *bev)
{
	// loop to handle read data
	
	evutil_socket_t fd = bufferevent_getfd(bev);
	LOG_DEBUG("fd=%d", fd);
	int ret = READ_MSG_WAIT;
	do
	{
		ret = HandleSocketReadMessage(bev);
	} 
	while (ret == READ_MSG_FINISH);

	return 0;
}

int NetService::HandleSocketReadMessage(struct bufferevent *bev)
{
	evutil_socket_t fd = bufferevent_getfd(bev);

	Mailbox *pmb = GetMailbox(fd);
	if (pmb == nullptr)
	{
		return READ_MSG_ERROR;
	}

	// 1. get input evbuffer and length
	// 2. check if has pluto in mailbox
	// 3. copy to pluto buffer
	// 4. if read msg finish, add into recv msg list, and clean mailbox pluto

	// get input evbuffer and length
	struct evbuffer *input = bufferevent_get_input(bev);
	const size_t input_len = evbuffer_get_length(input);

	LOG_DEBUG("input_len=%lu", input_len);
	if (input_len == 0)
	{
		return READ_MSG_WAIT;
	}

	char *buffer = nullptr;
	int nWanted = 0;
	ev_ssize_t nLen = 0;

	Pluto *pu = pmb->m_pluto;
	if (pu == nullptr)
	{
		// no pluto in mailbox

		if (input_len < PLUTO_MSGLEN_HEAD)
		{
			// data less then msg head
			return READ_MSG_WAIT;
		}

		// get msg head len
		char head[PLUTO_MSGLEN_HEAD];
		nLen= evbuffer_copyout(input, head, PLUTO_MSGLEN_HEAD);
		if (nLen < PLUTO_MSGLEN_HEAD)
		{
			return READ_MSG_WAIT;
		}

		// shift input data
		evbuffer_drain(input, nLen);

		// get msglen
		int msgLen = (int)ntohl(*(uint32_t *)head);
		if (msgLen > MSGLEN_MAX)
		{
			LOG_WARN("msg too long fd=%d msgLen=%d", fd, msgLen);
			// TODO should kick this connection?
		}

		// new a pluto
		pu = new Pluto(msgLen);
		pmb->m_pluto = pu;

		// copy msghead to buffer
		buffer = pu->GetBuffer();
		memcpy(buffer, head, PLUTO_MSGLEN_HEAD);
		buffer += PLUTO_MSGLEN_HEAD;

		pu->SetRecvLen(PLUTO_MSGLEN_HEAD);
		nWanted = msgLen - PLUTO_MSGLEN_HEAD;
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
	pu->SetMailbox(pmb);
	AddRecvMsg(pu);

	// clean mailbox pluto
	pmb->m_pluto = NULL;

	return READ_MSG_FINISH;
}

void NetService::AddRecvMsg(Pluto *pu)
{
	m_recvMsgs.push_back(pu);
}


int NetService::HandleSocketConnected(evutil_socket_t fd)
{
	Mailbox *pmb = GetMailbox(fd);
	if (pmb == NULL)
	{
		LOG_WARN("mailbox null fd=%d", fd);
		return 0;
	}

	m_world->HandleConnectToSuccess(pmb);
	return 0;
}

int NetService::HandleSocketClosed(evutil_socket_t fd)
{
	CloseMailbox(fd);
	return 0;
}

int NetService::HandleSocketError(evutil_socket_t fd)
{
	CloseMailbox(fd);
	return 0;
}

int NetService::HandleRecvPluto()
{
	while (!m_recvMsgs.empty())
	{
		Pluto *pu = m_recvMsgs.front();
		m_recvMsgs.pop_front();

		// core logic
		m_world->HandlePluto(*pu);

		delete pu;
	}
	return 0;
}

void NetService::CloseMailbox(int fd)
{
	Mailbox *pmb = GetMailbox(fd);
	if (pmb == nullptr)
	{
		LOG_WARN("mailbox null fd=%d", fd);
		return;
	}
	CloseMailbox(pmb);
}

void NetService::CloseMailbox(Mailbox *pmb)
{
	if (pmb->m_bev != nullptr)
	{
		bufferevent_free(pmb->m_bev);
		pmb->m_bev = nullptr;
	}
	else
	{
		LOG_WARN("m_bev null %d", pmb->GetMailboxId());
	}

	// notice to world
	m_world->HandleDisconnect(pmb);

	// push to list, delete by tick
	pmb->SetDeleteFlag();
	m_mb4del.push_back(pmb);
	m_fds.erase(pmb->GetFd());
}

int NetService::HandleSendPluto()
{
	// loop add mailbox, do send all
	std::list<Mailbox *> ls4del;
	for (auto iter = m_fds.begin(); iter != m_fds.end(); iter++)
	{
		Mailbox *pmb = iter->second;
		int ret = pmb->SendAll();
		if (ret != 0)
		{
			ls4del.push_back(pmb);
		}
	}

	// close error connect
	for (auto iter = ls4del.begin(); iter != ls4del.end(); iter++)
	{
		CloseMailbox(*iter);
	}

	return 0;
}

int NetService::HandleTickEvent()
{
	// 1. handle recv pluto
	// 2. handle send pluto
	// 3. delete mailbox

	// print some info
	// LOG_INFO("m_fds.size=%d m_mb4del.size=%d m_recvMsgs.size=%d", m_fds.size(), m_mb4del.size(), m_recvMsgs.size());
	
	// handle recv pluto
	HandleRecvPluto();

	// handle send pluto
	HandleSendPluto();

	// delete mailbox
	ClearContainer(m_mb4del);

	return 0;
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
	ns->HandleSocketReadEvent(bev);
}

static void event_cb(struct bufferevent *bev, short event, void *user_data)
{
	// handle other event
	NetService *ns = (NetService *)user_data;
	evutil_socket_t fd = bufferevent_getfd(bev);

	if (event & BEV_EVENT_CONNECTED)
	{
		LOG_DEBUG("******* event connected %d", fd);
		ns->HandleSocketConnected(fd);
	}
	else if (event & BEV_EVENT_EOF)
	{
		LOG_DEBUG("******* event eof fd=%d", fd);
		ns->HandleSocketClosed(fd);
	}
	else if (event & BEV_EVENT_ERROR)
	{
		LOG_ERROR("******* event error fd=%d errno=%d", fd, errno);
		ns->HandleSocketError(fd);
	}
	else if (event & BEV_EVENT_TIMEOUT)
	{
		LOG_ERROR("******* event timeout fd=%d event=%d errno=%d", fd, event, errno);
	}
	else
	{
		LOG_ERROR("******* unknow event fd=%d event=%d errno=%d", fd, event, errno);
	}
}

static void tick_cb(evutil_socket_t fd, short event, void *user_data)
{
	NetService *server = (NetService *)user_data;
	server->HandleTickEvent();
}

// for add timer
static void timer_cb(evutil_socket_t fd, short event, void *user_data)
{
	TimerMgr::OnTimer();
}

////////// callback end ]
