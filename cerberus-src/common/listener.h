
#pragma once

#include <stdint.h>

class Listener
{
public:
	Listener(int m_fd);
	~Listener();

	int GetFd();
	void SetFd(int fd);

	int64_t GetListenId();

private:
	int m_fd;
	int64_t m_listenId;
};
