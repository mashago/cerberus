
#include "listener.h"

static int64_t _get_listen_id()
{
	static int64_t listenId = 1;
	return listenId++;
}

Listener::Listener(int fd) : m_fd(fd), m_listenId(-1)
{
	m_listenId = _get_listen_id();
}

