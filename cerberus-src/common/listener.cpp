
#include "listener.h"

static int64_t gen_listen_id()
{
	static int64_t listenId = 1;
	return listenId++;
}

Listener::Listener(int fd) : m_fd(fd), m_listenId(-1)
{
	m_listenId = gen_listen_id();
}

int Listener::GetFd()
{
	return m_fd;
}

void Listener::SetFd(int fd)
{
	m_fd = fd;
}

int64_t Listener::GetListenId()
{
	return m_listenId;
}
