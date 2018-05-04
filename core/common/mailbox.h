
#pragma once

#include <list>

struct bufferevent;
class Pluto;

class Mailbox
{
public:
	Mailbox();
	~Mailbox();

	int GetFd()
	{
		return m_fd;
	}
	void SetFd(int fd)
	{
		m_fd = fd;
	}

	int64_t GetMailboxId()
	{
		return m_mailboxId;
	}

	Pluto *GetRecvPluto()
	{
		return m_recvPluto;
	}
	void SetRecvPluto(Pluto *ptr)
	{
		m_recvPluto = ptr;
	}

	struct bufferevent *GetBEV()
	{
		return m_bev;
	}
	void SetBEV(struct bufferevent *bev)
	{
		m_bev = bev;
	}

	void SetDeleteFlag()
	{
		m_bDeleteFlag = true;
	}
	bool IsDelete()
	{
		return m_bDeleteFlag;
	}

	void PushSendPluto(Pluto *u);
	int SendAll();

private:
	int m_fd;
	int64_t m_mailboxId;
	Pluto *m_recvPluto;
	struct bufferevent *m_bev;
	bool m_bDeleteFlag;
	std::list<Pluto *> m_tobeSend;
	int m_sendPos;
};

