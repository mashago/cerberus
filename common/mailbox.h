
#pragma once

extern "C"
{
#include <event2/bufferevent.h>
}
#include <list>
#include "common.h"
#include "pluto.h"

class Mailbox
{
public:
	Mailbox(E_CONN_TYPE type);
	~Mailbox();

	int GetFd()
	{
		return m_fd;
	}

	void SetFd(int fd)
	{
		m_fd = fd;
	}

	int GetMailboxId()
	{
		return m_fd;
	}

	void SetMailboxId(int fd)
	{
		m_fd = fd;
	}

	void SetDeleteFlag()
	{
		m_bDeleteFlag = true;
	}

	bool IsDelete()
	{
		return m_bDeleteFlag;
	}

	void PushPluto(Pluto *u);
	int SendAll();

// private:
	E_CONN_TYPE m_fdType;
	int m_fd;
	Pluto *m_pluto;
	struct bufferevent *m_bev;
	bool m_bDeleteFlag;
	std::list<Pluto *> m_tobeSend;
	int m_sendPos;
};

