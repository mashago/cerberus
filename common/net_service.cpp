
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

static void listen_cb(struct evconnlistener *listener, evutil_socket_t fd, struct sockaddr *sa, int socklen, void *user_data);
static void read_cb(struct bufferevent *bev, void *user_data);
static void event_cb(struct bufferevent *bev, short event, void *user_data);
static void timer_cb(evutil_socket_t fd, short event, void *user_data);

NetService::NetService() : m_mainEvent(0), m_evconnlistener(0)
{
}

NetService::~NetService()
{
}

int NetService::LoadConfig(const char *path)
{
	// load other net service config
	return 0;
}

int NetService::Service(const char *addr, unsigned int port)
{
	if (StartService(addr, port))
	{
		return -1;
	}

	event_base_dispatch(m_mainEvent);

	if (m_timerEvent)
	{
		event_del(m_timerEvent);
		event_free(m_timerEvent);
		m_timerEvent = NULL;
	}

	event_base_free(m_mainEvent);

	return 0;
}

int NetService::StartService(const char *addr, unsigned int port)
{
	// 1. new event_base
	// 2. init listener
	// 3. set nonblock
	// 4. init timer

	// new event_base
	m_mainEvent = event_base_new();
	if (!m_mainEvent)
	{
		LOG_ERROR("event_base_new fail");
		return -1;
	}

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
	evutil_socket_t listen_fd = evconnlistener_get_fd(m_evconnlistener);
	evutil_make_socket_nonblocking(listen_fd);

	// init timer
	m_timerEvent = event_new(m_mainEvent, -1, EV_PERSIST, timer_cb, this);
	struct timeval tv;
	// tv.tv_sec = 0;
	tv.tv_sec = 3;
	tv.tv_usec = 50 * 1000;
	if (event_add(m_timerEvent, &tv) != 0)
	{
		LOG_ERROR("StartService: event_add timer fail");
		return -1;
	}

	return 0;
}

MailBox *NetService::GetClientMailBox(int fd)
{
	auto iter = m_fds.find(fd);
	if (iter == m_fds.end())
	{
		return nullptr;
	}
	return iter->second;
}


int NetService::HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen)
{
	LOG_DEBUG("fd=%d", fd);

	// 1. check connection num
	// 2. check connection is valide
	// 3. set fd non-block
	// 4. accept clinet
	
	// check connection num
	// TODO
	
	// check connection is valide
	// TODO

	// set fd non-block
	evutil_make_socket_nonblocking(fd);

	// accept client
	OnNewFdAccepted(fd);

	return 0;
}

int NetService::OnNewFdAccepted(int fd)
{

	// 1. create mailbox and init
	// 2. init buffer socket
	
	// create mailbox and init
	AddFdAndMb(fd, FD_TYPE_ACCEPT);

	// init buffer socket
	MailBox *pmb = GetClientMailBox(fd);
	if (!pmb)
	{
		LOG_ERROR("mailbox null fd=%d", fd);
		return -1;
	}

	struct bufferevent *bev = bufferevent_socket_new(m_mainEvent, fd, BEV_OPT_CLOSE_ON_FREE | BEV_OPT_DEFER_CALLBACKS);
	bufferevent_setcb(bev, read_cb, NULL, event_cb, (void *)this);
	bufferevent_enable(bev, EV_READ); // XXX consider set EV_PERSIST ?

	pmb->m_bev = bev;

	return 0;
}

void NetService::AddFdAndMb(int fd, EFDTYPE type)
{
	MailBox *pmb = new MailBox(type);

	// check if is trust connect
	// TODO
	
	AddFdAndMb(fd, pmb);
}

void NetService::AddFdAndMb(int fd, MailBox *pmb)
{
	pmb->SetFd(fd);

	auto iter = m_fds.lower_bound(fd);
	if (iter != m_fds.end() && iter->first == fd)
	{
		// still has old mailbox
		MailBox *oldmb = iter->second;
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
	LOG_DEBUG("fd=%d", fd);
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

	MailBox *pmb = GetClientMailBox(fd);
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

	Pluto *u = pmb->m_pluto;
	if (u == nullptr)
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

		int msgLen = ntohl(*(uint32_t *)head);
		if (msgLen > MSGLEN_MAX)
		{
			LOG_WARN("msg too long fd=%d msgLen=%d", fd, msgLen);
			// TODO should kick this connection?
		}

		// new a pluto
		u = new Pluto(msgLen);
		pmb->m_pluto = u;

		// copy msghead to buffer
		buffer = u->m_recvBuffer;
		memcpy(buffer, head, PLUTO_MSGLEN_HEAD);
		buffer += PLUTO_MSGLEN_HEAD;

		u->m_recvLen = PLUTO_MSGLEN_HEAD;
		nWanted = msgLen - PLUTO_MSGLEN_HEAD;
	}

	else
	{
		// already has pluto in mailbox
		buffer = u->m_recvBuffer + u->m_recvLen;
		nWanted = u->m_bufferSize - u->m_recvLen;
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
		u->m_recvLen = u->m_recvLen + nLen;
		return READ_MSG_WAIT;
	}

	// get a full msg
	// add into recv msg list
	u->m_recvLen = u->m_bufferSize;
	u->m_pmb = pmb;
	m_recvMsgs.push_back(u);

	// clean mailbox pluto
	pmb->m_pluto = NULL;

	return READ_MSG_FINISH;
}


int NetService::HandleSocketConnected(evutil_socket_t fd)
{
	return 0;
}

int NetService::HandleSocketClosed(evutil_socket_t fd)
{
	MailBox *pmb = GetClientMailBox(fd);
	if (pmb == NULL)
	{
		LOG_WARN("mailbox null fd=%d", fd);
		return 0;
	}

	// TODO broadcast to world
	RemoveFd(fd);
	pmb->m_bev = nullptr;

	return 0;
}

int NetService::HandleSocketError(evutil_socket_t fd)
{
	MailBox *pmb = GetClientMailBox(fd);
	if (pmb == nullptr)
	{
		return 0;
	}

	RemoveFd(fd);
	pmb->m_bev = nullptr;

	return 0;
}

void NetService::RemoveFd(int fd)
{
	auto iter = m_fds.find(fd);
	if (iter == m_fds.end())
	{
		return;
	}

	MailBox *pmb = iter->second;
	if (pmb->m_fdType == FD_TYPE_ACCEPT)
	{
		// client
		// push to list, delete by tick
		pmb->SetDeleteFlag();
		m_mb4del.push_back(pmb);
		m_fds.erase(iter);
	}
	else if (pmb->m_fdType == FD_TYPE_MAILBOX)
	{
		// server
		// try reconnect
		// TODO
	}
}


int NetService::HandlePluto(Pluto *u)
{
	LOG_DEBUG("u->m_bufferSize=%d", u->m_bufferSize);
	std::string buffer(u->m_recvBuffer, u->m_bufferSize);
	LOG_DEBUG("msgId=[%d] buffer=[%s]", u->GetMsgId(), buffer.c_str() + PLUTO_FILED_BEGIN_POS);

	MailBox *pmb = u->m_pmb;
	if (pmb == nullptr)
	{
		LOG_ERROR("mailbox null");
		return 0;
	}

	if (pmb->IsDelete())
	{
		// mailbox will be delete, client is already disconnect, no need to handle this pluto
		LOG_INFO("mailbox delete fd=%d", pmb->m_fd);
		return 0;
	}

	// do core logic here
	// TODO

	return 0;
}

int NetService::HandleRecvPluto()
{
	while (!m_recvMsgs.empty())
	{
		Pluto *u = m_recvMsgs.front();
		m_recvMsgs.pop_front();
		HandlePluto(u);
		delete u;
	}
	return 0;
}

int NetService::HandleSendPluto()
{
	return 0;
}

int NetService::HandleSocketTickEvent()
{
	// 1. handle recv pluto
	// 2. handle send pluto
	// 3. delete mailbox

	// print some info
	LOG_INFO("m_fds.size=%d m_mb4del.size=%d m_recvMsgs.size=%d", m_fds.size(), m_mb4del.size(), m_recvMsgs.size());
	
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

	bool bFinished = false;
	if (event & BEV_EVENT_CONNECTED)
	{
		LOG_DEBUG("event connected %d", fd);
		ns->HandleSocketConnected(fd);
	}
	else if (event & BEV_EVENT_EOF)
	{
		LOG_DEBUG("event eof fd=%d", fd);
		ns->HandleSocketClosed(fd);
		bFinished = true;
	}
	else if (event & BEV_EVENT_ERROR)
	{
		LOG_ERROR("event error fd=%d errno=%d", fd, errno);
		ns->HandleSocketError(fd);
		bFinished = true;
	}

	if (bFinished)
	{
		bufferevent_free(bev);
	}

}

static void timer_cb(evutil_socket_t fd, short event, void *user_data)
{
	// LOG_DEBUG("fd=%d", fd);
	NetService *server = (NetService *)user_data;
	server->HandleSocketTickEvent();
}

////////// callback end ]