/**
 project base on libevent2.0
  **/
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

#include <event2/event.h>
#include <event2/listener.h>
#include <event2/util.h>
#include <event2/bufferevent.h>
#include <event2/buffer.h>
}

#include <string>
#include "logger.h"
#include "client.h"
#include "command.h"
#include "commandfactory.h"


#define SERVER_HOST "0.0.0.0"
#define SERVER_PORT 7711
#define CLIENT_NUM 1 // max 337 in cygwin

Client *g_clientlist = nullptr;

void HandleInput(const char *buffer, int len);
void stdin_cb(evutil_socket_t fd, short what, void *user_data);

struct event * CreateStdinEvent(struct event_base *mainEvent)
{
	struct event *ev = event_new(mainEvent, STDIN_FILENO, EV_READ | EV_PERSIST, stdin_cb, (void *)mainEvent);
	int ret = event_add(ev, NULL);
	if (ret != 0)
	{
		LOG_ERROR("event_add fail");
		event_free(ev);
		return NULL;
	}
	return ev;
}

void stdin_cb(evutil_socket_t fd, short what, void *user_data)
{
	struct event_base *mainEvent = (struct event_base *)user_data;

	const int MAX_BUFFER = 1024;
	char buffer[MAX_BUFFER] = {0};
	int len = read(fd, buffer, MAX_BUFFER);
	if (len == 0)
	{
		// EOF
		return;
	}

	if (len < 0)
	{
		LOG_ERROR("read stdin fail");
		event_base_loopexit(mainEvent, NULL);
		return;
	}

	// LOG_DEBUG("buffer=[%s]", buffer);
	HandleInput(buffer, len);
}

void HandleInput(const char *buffer, int len)
{
	CommandFactory *factory = CommandFactory::Instance();
	// client handle command
	for (int i = 0; i < CLIENT_NUM; i++)
	{
		Client *c = g_clientlist+i;
		if (!c->IsConnect())
		{
			continue;
		}

		Command *cmd = factory->CreateCommand(buffer, len);
		if (!cmd)
		{
			continue;
		}
		c->PushCommand(cmd);
	}
}

bool CreateClient()
{
	g_clientlist = new Client[CLIENT_NUM];
	if (!g_clientlist)
	{
		return false;
	}

	// init 
	for (int i = 0; i < CLIENT_NUM; i++)
	{
		Client *c = g_clientlist+i;
		if (!c->Init(SERVER_HOST, SERVER_PORT))
		{
			return false;
		}
	}
	LOG_DEBUG("init success");

	// run
	for (int i = 0; i < CLIENT_NUM; i++)
	{
		Client *c = g_clientlist+i;
		if (!c->Run())
		{
			return false;
		}
	}
	LOG_DEBUG("run success");

	return true;
}


int main(int argc, char **argv)
{
	LOG_DEBUG("hello %s", argv[0]);

	// create client
	if (!CreateClient())
	{
		LOG_ERROR("CreateClient fail");
		return 0;
	}

	// create main event
	struct event_base *mainEvent = event_base_new();
	if (mainEvent == NULL)
	{
		LOG_ERROR("event_base_new fail");
		return 0;
	}

	// create stdin event
	struct event *stdinEvent = CreateStdinEvent(mainEvent);
	if (stdinEvent == NULL)
	{
		LOG_ERROR("CreateStdinEvent fail");
		return 0;
	}

	// main loop
	int ret = event_base_dispatch(mainEvent);
	LOG_DEBUG("event_base_dispatch ret=%d", ret);

	// clean up
	event_free(stdinEvent);
	event_base_free(mainEvent);

	return 0;
}

