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

#include "pluto.h"

#define SERVER_HOST "0.0.0.0"
#define SERVER_PORT 7711

// bufferevent data callback
// typedef void (*bufferevent_data_cb)(struct bufferevent *bev, void *ctx);
void read_cb(struct bufferevent *bev, void *user_data);

// bufferevent event callback
// typedef void (*bufferevent_event_cb)(struct bufferevent *bev, short what, void *ctx);
void event_cb(struct bufferevent *bev, short what, void *user_data);

// stdin callback
// typedef void (*event_callback_fn)(evutil_socket_t, short, void *);
void stdin_cb(evutil_socket_t, short what, void *user_data);


void read_cb(struct bufferevent *bev, void *user_data)
{
	// handle read event
	
	// struct event_base *main_event = (struct event_base *)user_data;
	evutil_socket_t fd = bufferevent_getfd(bev);
	printf("read_cb: fd=%d\n", fd);

	// 1. get input evbuffer and length
	struct evbuffer *input = bufferevent_get_input(bev);
	const size_t input_len = evbuffer_get_length(input);
	printf("input_len=%lu\n", input_len);

	// local buffer must get all data from input because read_cb will not active again even if still has data in input, until receive client data next time
	char *in_buffer = (char *)calloc(1, input_len+1); 

	// 2. copy to local buffer
	int n = evbuffer_copyout(input, in_buffer, input_len);
	printf("n=%d in_buffer=%s\n", n, in_buffer);

	// 3. remove header data in evbuffer
	evbuffer_drain(input, n);

	free(in_buffer);
}

void event_cb(struct bufferevent *bev, short what, void *user_data)
{
	// handle other event
	printf("event_cb: what=%d\n", what);

	// struct event_base *main_event = (struct event_base *)user_data;
	evutil_socket_t fd = bufferevent_getfd(bev);
	struct event_base *main_event = (struct event_base *)user_data;

	if (what & BEV_EVENT_CONNECTED)
	{
		printf("event_cb: event connected fd=%d\n", fd);
	}
	else if (what & BEV_EVENT_EOF)
	{
		printf("event_cb: event eof fd=%d\n", fd);
		event_base_loopexit(main_event, NULL);
	}
	else if (what & BEV_EVENT_ERROR)
	{
		printf("event_cb: event error fd=%d errno=%d\n", fd, errno);
		event_base_loopexit(main_event, NULL);
	}

}

void stdin_cb(evutil_socket_t fd, short what, void *user_data)
{
	printf("stdin_cb: fd=%d\n", fd);
	struct bufferevent *bev = (struct bufferevent *)user_data;

	char buffer[MSGLEN_MAX];
	int len = read(fd, buffer+MSGLEN_TEXT_POS, MSGLEN_MAX-MSGLEN_TEXT_POS);
	if (len == 0)
	{
		// EOF
		return;
	}

	if (len < 0)
	{
		printf("stdin_cb: read stdin fail\n");
		struct event_base *main_event = bufferevent_get_base(bev);
		event_base_loopexit(main_event, NULL);
		return;
	}

	int msgLen = MSGLEN_HEAD + MSGLEN_MSGID + len;
	static int msgId = 0;

	char *ptr = buffer;
	*(uint32_t *)ptr = htonl(msgLen);
	ptr += MSGLEN_HEAD;
	*(uint32_t *)ptr = htonl(++msgId);

	// put into bev output buffer
	struct evbuffer *output = bufferevent_get_output(bev);
	evbuffer_add(output, buffer, msgLen);

	/*
	// use this function pair, to avoid memory copy
	// int evbuffer_reserve_space(struct evbuffer *buf, ev_ssize_t size, struct evbuffer_iovec *vec, int n_vec);
	// int evbuffer_commit_space(struct evbuffer *buf, struct evbuffer_iovec *vec, int n_vecs);

	const int MAX_BUFFER = 1024;
	struct evbuffer *output = bufferevent_get_output(bev);
	struct evbuffer_iovec v[1]; // the vector struct to access evbuffer directly, without memory copy

	// 1. reserve space
	int res = evbuffer_reserve_space(output, MAX_BUFFER, v, 1);
	const size_t iov_len = v[0].iov_len; // iov_len may bigger then reserve num
	// printf("iov_len=%zu\n", iov_len);
	if (res <= 0 || iov_len == 0)
	{
		printf("stdin_cb: evbuffer_reserve_space fail\n");
		return;
	}

	// read from stdin into iov_base
	int len = read(fd, (char *)v[0].iov_base, iov_len-1);
	if (len < 0)
	{
		printf("stdin_cb: read stdin fail\n");
		struct event_base *main_event = bufferevent_get_base(bev);
		event_base_loopexit(main_event, NULL);
		return;
	}

	// 2. reset iov_len to send buffer size
	v[0].iov_len = len;

	// 3. commit space
	if (evbuffer_commit_space(output, v, 1) != 0)
	{
		printf("stdin_cb: evbuffer_commit_space fail\n");
		return;
	}
	*/

}


struct bufferevent * create_connect_event(struct event_base *main_event)
{
	// 1. init a sin
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_family = PF_INET;
	sin.sin_port = htons(SERVER_PORT);
	int ip_num = inet_addr(SERVER_HOST);
	sin.sin_addr.s_addr = ip_num;

	// 2. init a socket
	// int client_fd = socket(PF_INET, SOCK_STREAM, 0);
	// evutil_make_socket_nonblocking(client_fd);

	// 3. create a socket bufferevent
	// struct bufferevent *bufferevent_socket_new(struct event_base *base, evutil_socket_t fd, int options);
	// struct bufferevent *bev = bufferevent_socket_new(main_event, client_fd, BEV_OPT_CLOSE_ON_FREE);
	struct bufferevent *bev = bufferevent_socket_new(main_event, -1, BEV_OPT_CLOSE_ON_FREE);

	// 4. bufferevent set callback
	// void bufferevent_setcb(struct bufferevent *bufev, bufferevent_data_cb readcb, bufferevent_data_cb writecb, bufferevent_event_cb eventcb, void *cbarg);
	bufferevent_setcb(bev, read_cb, NULL, event_cb, main_event);

	// 5. add event into poll
	// int bufferevent_enable(struct bufferevent *bufev, short event);
	// NOTE: no need EV_PERSIST?
	// bufferevent_enable(bev, EV_READ | EV_WRITE | EV_PERSIST);
	bufferevent_enable(bev, EV_READ | EV_WRITE);

	// 6. connect
	// int bufferevent_socket_connect(struct bufferevent *, struct sockaddr *, int);
	//  If the bufferevent does not already have a socket set, we allocate a new socket here and make it nonblocking before we begin.
	int ret = bufferevent_socket_connect(bev, (struct sockaddr *)&sin, sizeof(sin));
	if (ret < 0)
	{
		printf("create_connect_event: bufferevent connect fail\n");
		bufferevent_free(bev);
		return NULL;
	}

	return bev;
}

struct event * create_stdin_event(struct event_base *main_event, struct bufferevent *bev)
{
	struct event *stdin_event = event_new(main_event, STDIN_FILENO, EV_READ | EV_PERSIST, stdin_cb, (void *)bev);
	int ret = event_add(stdin_event, NULL);
	if (ret != 0)
	{
		printf("create_stdin_event: event_add fail\n");
		event_free(stdin_event);
		return NULL;
	}
	return stdin_event;
}


int main(int argc, char **argv)
{
	printf("hello %s\n", argv[0]);

	// 1. main base event init
	// struct event_base *event_base_new(void);
	struct event_base *main_event = event_base_new();
	if (main_event == NULL)
	{
		printf("event_base_new fail\n");
		return 0;
	}

	// 2. create client connect event
	struct bufferevent *bev = create_connect_event(main_event);
	if (bev == NULL)
	{
		printf("create_connect_event fail\n");
		return 0;
	}

	// 3. create stdin event
	struct event *stdin_event = create_stdin_event(main_event, bev);
	if (stdin_event == NULL)
	{
		printf("create_stdin_event fail\n");
		return 0;
	}

	// 4. main loop
	// int event_base_dispatch(struct event_base *);
	int ret = event_base_dispatch(main_event);
	printf("event_base_dispatch ret=%d\n", ret);

	// 5. clean up
	bufferevent_free(bev);
	event_free(stdin_event);
	event_base_free(main_event);

	return 0;
}

