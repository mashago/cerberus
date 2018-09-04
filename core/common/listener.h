
#pragma once

#include <stdint.h>

class Listener
{
public:
	Listener(int m_fd);
	~Listener();

	int GetFd()
	{
		return m_fd;
	}
	void SetFd(int fd)
	{
		m_fd = fd;
	}

	int64_t GetListenId()
	{
		return m_listenId;
	}

private:
	int m_fd;
	int64_t m_listenId;
};
