
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
#include "logger.h"
#include <string>
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
	if (StartServer(addr, port))
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

int NetService::StartServer(const char *addr, unsigned int port)
{
	// 1. new event_base
	// 2. init timer
	// 3. init listener
	// 4. set nonblock

	// new event_base
	m_mainEvent = event_base_new();
	if (!m_mainEvent)
	{
		LogError("%s: event_base_new fail", __FUNCTION__);
		return -1;
	}

	// init timer
	m_timerEvent = event_new(m_mainEvent, -1, EV_PERSIST, timer_cb, this);
	struct timeval tv;
	tv.tv_sec = 0;
	tv.tv_usec = 50 * 1000;
	if (event_add(m_timerEvent, &tv) != 0)
	{
		printf("StartServer: event_add timer fail\n");
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
		LogError("%s: new bind fail", __FUNCTION__);
		return -1;
	}

	// set nonblock
	evutil_socket_t listen_fd = evconnlistener_get_fd(m_evconnlistener);
	evutil_make_socket_nonblocking(listen_fd);

	return 0;
}

MailBox *NetService::GetClientMailBox(int fd)
{
	std::map<int, MailBox *>::iterator iter = m_fds.find(fd);
	if (iter == m_fds.end())
	{
		return NULL;
	}
	return iter->second;
}

int NetService::OnNewFdAccepted(int fd)
{
	// 1. new a mailbox
	// 2. new a bufferevent
	// 3. set callback
	// 4. add event into poll

	// 1.
	MailBox *pmb = new MailBox();

	m_fds[fd] = pmb;
	
	// 2.
	struct bufferevent *bev = bufferevent_socket_new(m_mainEvent, fd, BEV_OPT_CLOSE_ON_FREE | BEV_OPT_DEFER_CALLBACKS);

	// 3.
	bufferevent_setcb(bev, read_cb, NULL, event_cb, (void *)this);
	
	// 4.
	bufferevent_enable(bev, EV_READ);

	pmb->m_bev = bev;

	return 0;
}

int NetService::HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen)
{
	LogDebug("%s: fd=%d", __FUNCTION__, fd);
	// 1. set fd non-block

	// 1.
	evutil_make_socket_nonblocking(fd);

	OnNewFdAccepted(fd);

	return 0;
}

int NetService::HandleSocketReadEvent(struct bufferevent *bev)
{
	evutil_socket_t fd = bufferevent_getfd(bev);
	LogDebug("%s: fd=%d", __FUNCTION__, fd);
	int ret = 0;
	do
	{
		ret = HandleSocketReadMessage(bev);
	} while (ret != 1);

	return 0;
}

int NetService::HandleSocketReadMessage(struct bufferevent *bev)
{
	
	evutil_socket_t fd = bufferevent_getfd(bev);
	printf("HandleSocketReadMessage: fd=%d\n", fd);

	MailBox *pmb = GetClientMailBox(fd);
	if (pmb == NULL)
	{
		return -1;
	}

	// 1. get input evbuffer and length
	// 2. copy to local buffer
	// 3. remove header data in evbuffer
	// 4. debug test logic, get output evbuffer and add to send msg to client

	// get input evbuffer and length
	struct evbuffer *input = bufferevent_get_input(bev);
	const size_t input_len = evbuffer_get_length(input);
	/*
<<<<<<< HEAD
	LogDebug("%s input_len=%lu", __FUNCTION__, input_len);

	// NOTE
	// copy to local buffer
	// must copy all data from input to local buffer, because read_cb will not active again even if still has data in input, until receive client data next time
	char *in_buffer = (char *)calloc(1, input_len+1); 
	int n = evbuffer_copyout(input, in_buffer, input_len);
	LogDebug("%s n=%d in_buffer=%s", __FUNCTION__, n, in_buffer);

	// remove data in evbuffer
	evbuffer_drain(input, n);

	// DEBUG get output evbuffer and add to send msg to client
	struct evbuffer *output = bufferevent_get_output(bev);
	char out_buffer[100];
	sprintf(out_buffer, "hello %lu", time(NULL));
	evbuffer_add(output, out_buffer, strlen(out_buffer));
=======
*/

	printf("input_len=%lu\n", input_len);
	if (input_len == 0)
	{
		return 0;
	}

	ev_ssize_t nLen = 0;
	Pluto *u = pmb->m_pluto;
	if (u == NULL)
	{
		if (input_len < PLUTO_MSGLEN_HEAD)
		{
			return 0;
		}

		char head[PLUTO_MSGLEN_HEAD];
		nLen= evbuffer_copyout(input, head, PLUTO_MSGLEN_HEAD);
		if (nLen < PLUTO_MSGLEN_HEAD)
		{
			return 0;
		}

		evbuffer_drain(input, nLen);
		int msgLen = ntohl(*(uint32_t *)head);
		if (msgLen > MSGLEN_MAX)
		{
			// warn it
		}

		u = new Pluto(msgLen);
		char *buffer = u->m_recvBuffer;
		memcpy(buffer, head, PLUTO_MSGLEN_HEAD);

		int nWanted = msgLen - PLUTO_MSGLEN_HEAD;
		nLen = evbuffer_copyout(input, buffer+PLUTO_MSGLEN_HEAD, nWanted);
		if (nLen <= 0)
		{
			// no more data
			u->m_recvLen = PLUTO_MSGLEN_HEAD;
			pmb->m_pluto = u;
			return 0;
		}

		evbuffer_drain(input, nLen);
		if (nLen != nWanted)
		{
			// data not enough
			u->m_recvLen = PLUTO_MSGLEN_HEAD + nLen;
			pmb->m_pluto = u;
			return 0;
		}

		// get a full msg
		u->m_pmb = pmb;
		m_recvMsgs.push_back(u);
		pmb->m_pluto = NULL;

		return 1;
	}

	// already has pluto in mailbox
	else
	{
		char *buffer = u->m_recvBuffer;
		int recvLen = u->m_recvLen;
		int nWanted = u->m_bufferSize - recvLen;
		nLen = evbuffer_copyout(input, buffer+recvLen, nWanted);
		if (nLen <= 0)
		{
			return 0;
		}
		
		evbuffer_drain(input, nLen);
		if (nLen != nWanted)
		{
			u->m_recvLen = recvLen + nLen;
			return 0;
		}

		// get a full msg
		u->m_pmb = pmb;
		m_recvMsgs.push_back(u);
		pmb->m_pluto = NULL;

		return 1;
	}

	return 0;
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
		return 0;
	}
	pmb->m_bev = NULL;
	m_fds.erase(fd);
	return 0;
}

int NetService::HandleSocketError(evutil_socket_t fd)
{
	MailBox *pmb = GetClientMailBox(fd);
	if (pmb == NULL)
	{
		return 0;
	}
	pmb->m_bev = NULL;
	m_fds.erase(fd);
	return 0;
}

int NetService::HandlePluto(Pluto *u)
{
	// do core logic here
	// TODO
	printf("HandleRecvPluto: u->m_bufferSize=%d\n", u->m_bufferSize);
	std::string buffer(u->m_recvBuffer, u->m_bufferSize);
	printf("%s\n", buffer.c_str()+PLUTO_MSGLEN_HEAD);
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
	// 1. handle pluto
	// 2. handle send pluto
	// 3. TODO delete pluto
	
	// 1.
	HandleRecvPluto();

	// 2.
	HandleSendPluto();

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
		LogDebug("%s: event connected %d", __FUNCTION__, fd);
		ns->HandleSocketConnected(fd);
	}
	else if (event & BEV_EVENT_EOF)
	{
		LogDebug("%s: event eof fd=%d", __FUNCTION__, fd);
		ns->HandleSocketClosed(fd);
		bFinished = true;
	}
	else if (event & BEV_EVENT_ERROR)
	{
		LogError("%s: event error fd=%d errno=%d", __FUNCTION__, fd, errno);
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
	NetService *server = (NetService *)user_data;
	server->HandleSocketTickEvent();
}

////////// callback end ]
