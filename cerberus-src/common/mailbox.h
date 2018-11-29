
#pragma once

#include <list>

struct bufferevent;
class Pluto;

class Mailbox
{
public:
	Mailbox();
	~Mailbox();

	int GetFd();
	void SetFd(int fd);

	int64_t GetMailboxId();

	Pluto *GetRecvPluto();
	void SetRecvPluto(Pluto *ptr);

	struct bufferevent *GetBEV();
	void SetBEV(struct bufferevent *bev);

	void SetDelete(bool flag);
	bool IsDelete();

	void Push(Pluto *u);
	int SendAll();

private:
	int m_fd;
	int64_t m_mailboxId;
	Pluto *m_recvPluto;
	struct bufferevent *m_bev;
	bool m_deleteFlag;
	std::list<Pluto *> m_tobeSend;
	int m_sendPos;
};

