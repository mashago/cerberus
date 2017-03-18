
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
#include "net_service.h"

static void listen_cb(struct evconnlistener *listener, evutil_socket_t fd, struct sockaddr *sa, int socklen, void *user_data);
static void read_cb(struct bufferevent *bev, void *user_data);
static void event_cb(struct bufferevent *bev, short event, void *user_data);

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

	event_base_free(m_mainEvent);

	return 0;
}

int NetService::StartServer(const char *addr, unsigned int port)
{
	// 1. new event_base
	// 2. init listener
	// 3. set nonblock

	// new event_base
	m_mainEvent = event_base_new();
	if (!m_mainEvent)
	{
		LogError("%s: event_base_new fail", __FUNCTION__);
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

int NetService::HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen)
{
	LogDebug("%s: fd=%d", __FUNCTION__, fd);

	// 1. set fd non-block
	// 2. new a bufferevent
	// 3. set callback
	// 4. add event into poll

	// 1.
	evutil_make_socket_nonblocking(fd);

	// 2.
	struct bufferevent *bev = bufferevent_socket_new(m_mainEvent, fd, BEV_OPT_CLOSE_ON_FREE | BEV_OPT_DEFER_CALLBACKS);

	// 3.
	bufferevent_setcb(bev, read_cb, NULL, event_cb, (void *)this);
	
	// 4.
	bufferevent_enable(bev, EV_READ);

	return 0;
}

int NetService::HandleSocketReadEvent(struct bufferevent *bev)
{
	evutil_socket_t fd = bufferevent_getfd(bev);
	LogDebug("%s: fd=%d", __FUNCTION__, fd);

	// 1. get input evbuffer and length
	// 2. copy to local buffer
	// 3. remove header data in evbuffer
	// 4. debug test logic, get output evbuffer and add to send msg to client

	// get input evbuffer and length
	struct evbuffer *input = bufferevent_get_input(bev);
	const size_t input_len = evbuffer_get_length(input);
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

	free(in_buffer);

	return 0;
}

int NetService::HandleSocketConnected(evutil_socket_t fd)
{
	return 0;
}

int NetService::HandleSocketClosed(evutil_socket_t fd)
{
	return 0;
}

int NetService::HandleSocketError(evutil_socket_t fd)
{
	return 0;
}


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
