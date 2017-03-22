
extern "C"
{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <strings.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <time.h>
#include <errno.h>
}

#include <thread>
#include "client.h"
#include "logger.h"
#include "util.h"
#include "pluto.h"


// bufferevent data callback
// typedef void (*bufferevent_data_cb)(struct bufferevent *bev, void *ctx);
void read_cb(struct bufferevent *bev, void *user_data);

// bufferevent event callback
// typedef void (*bufferevent_event_cb)(struct bufferevent *bev, short what, void *ctx);
void event_cb(struct bufferevent *bev, short what, void *user_data);

void timer_cb(evutil_socket_t fd, short event, void *user_data);


Client::Client() : m_mainEvent(nullptr), m_bev(nullptr), m_timerEvent(nullptr)
{
}

Client::~Client()
{
}


bool Client::Init(const char *addr, int port)
{
	m_addr = std::string(addr);
	m_port = port;

	m_mainEvent = event_base_new();
	if (m_mainEvent == NULL)
	{
		LOG_ERROR("event_base_new fail");
		return false;
	}

	if (!CreateConnection())
	{
		LOG_ERROR("create connection fail");
		return false;
	}

	if (!CreateTimer())
	{
		LOG_ERROR("create tick fail");
		return false;
	}

	return true;
}

bool Client::CreateConnection()
{
	// init a sin
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_family = PF_INET;
	int ip_num = inet_addr(m_addr.c_str());
	sin.sin_addr.s_addr = ip_num;
	sin.sin_port = htons(m_port);

	// create a socket bufferevent
	// struct bufferevent *bufferevent_socket_new(struct event_base *base, evutil_socket_t fd, int options);
	m_bev = bufferevent_socket_new(m_mainEvent, -1, BEV_OPT_CLOSE_ON_FREE);
	if (!m_bev)
	{
		return false;
	}

	// bufferevent set callback
	// void bufferevent_setcb(struct bufferevent *bufev, bufferevent_data_cb readcb, bufferevent_data_cb writecb, bufferevent_event_cb eventcb, void *cbarg);
	bufferevent_setcb(m_bev, read_cb, NULL, event_cb, m_mainEvent);

	// add event into poll
	// int bufferevent_enable(struct bufferevent *bufev, short event);
	// NOTE: no need EV_PERSIST?
	// bufferevent_enable(bev, EV_READ | EV_WRITE | EV_PERSIST);
	bufferevent_enable(m_bev, EV_READ | EV_WRITE);

	// connect
	// int bufferevent_socket_connect(struct bufferevent *, struct sockaddr *, int);
	//  If the bufferevent does not already have a socket set, we allocate a new socket here and make it nonblocking before we begin.
	int ret = bufferevent_socket_connect(m_bev, (struct sockaddr *)&sin, sizeof(sin));
	if (ret < 0)
	{
		LOG_ERROR("bufferevent connect fail");
		bufferevent_free(m_bev);
		return false;
	}

	return true;
}

bool Client::CreateTimer()
{
	m_timerEvent = event_new(m_mainEvent, -1, EV_PERSIST, timer_cb, this);
	struct timeval tv;
	tv.tv_sec = 0;
	tv.tv_usec = 50 * 1000;
	if (event_add(m_timerEvent, &tv) != 0)
	{
		LOG_ERROR("fail");
		return false;
	}
	return true;
}

bool Client::Run()
{
	m_thread = std::thread([&]()
		{
			int ret = event_base_dispatch(m_mainEvent);
			LOG_WARN("client run finish ret=%d", ret);
		}
	);
	LOG_DEBUG("success");

	return true;
}

void Client::Send(Command *cmd)
{
	std::unique_lock<std::mutex> lock(m_mtx);
	
	m_cmdList.push_back(cmd);
}

void Client::HandleTickEvent()
{
	do
	{
		Command *c = GetCommand();
		if (!c)
		{
			break;
		}

		std::string msg = c->Pack();

		struct evbuffer *output = bufferevent_get_output(m_bev);
		evbuffer_add(output, msg.c_str(), msg.size());

		delete c;
	}
	while (true);
}

Command * Client::GetCommand()
{
	std::unique_lock<std::mutex> lock(m_mtx);
	
	if (m_cmdList.empty())
	{
		return nullptr;
	}

	Command *c = m_cmdList.front();
	m_cmdList.pop_front();
	return c;
}


void read_cb(struct bufferevent *bev, void *user_data)
{
	// handle read event
	
	do
	{
		// get input evbuffer and length
		struct evbuffer *input = bufferevent_get_input(bev);
		const size_t inputLen = evbuffer_get_length(input);
		// LOG_DEBUG("inputLen=%lu", inputLen);

		// NOTE:
		// local buffer must get all data from input because read_cb will not active again even if still has data in input, until receive client data next time
		
		// read head
		char head[PLUTO_MSGLEN_HEAD];
		ev_ssize_t nLen = evbuffer_copyout(input, head, PLUTO_MSGLEN_HEAD);
		if (nLen < PLUTO_MSGLEN_HEAD)
		{
			// head not complete
			return;
		}

		int msgLen = (int)ntohl(*(uint32_t *)head);
		// LOG_DEBUG("msgLen=%d", msgLen);
		if (msgLen > (int)inputLen)
		{
			// msg not complete
			return;
		}

		Pluto *u = new Pluto(msgLen);
		// copy to local buffer
		nLen = evbuffer_copyout(input, u->GetBuffer(), msgLen);

		// shift data
		evbuffer_drain(input, nLen);

		// evutil_socket_t fd = bufferevent_getfd(bev);
		// LOG_DEBUG("fd=%d", fd);
		u->Print();

		delete u;
	} 
	while (true);

}

void event_cb(struct bufferevent *bev, short what, void *user_data)
{
	// handle other event
	LOG_DEBUG("what=%d", what);

	// struct event_base *main_event = (struct event_base *)user_data;
	evutil_socket_t fd = bufferevent_getfd(bev);
	struct event_base *main_event = (struct event_base *)user_data;

	if (what & BEV_EVENT_CONNECTED)
	{
		LOG_DEBUG("event connected fd=%d", fd);
	}
	else if (what & BEV_EVENT_EOF)
	{
		LOG_DEBUG("event eof fd=%d", fd);
		event_base_loopexit(main_event, NULL);
	}
	else if (what & BEV_EVENT_ERROR)
	{
		LOG_DEBUG("event error fd=%d errno=%d", fd, errno);
		event_base_loopexit(main_event, NULL);
	}

}

void timer_cb(evutil_socket_t fd, short event, void *user_data)
{
	// get cmd from list
	// make send buffer
	// do send
	Client *client = (Client *)user_data;
	client->HandleTickEvent();
}
