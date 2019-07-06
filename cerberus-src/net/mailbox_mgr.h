
#pragma once

#include <set>
#include <map>
#include <list>

class Mailbox;

class MailboxMgr
{
public:
	Mailbox *NewMailbox(int fd);
	void CloseMailbox(Mailbox *pmb);
	Mailbox *GetMailboxByFd(int fd);
	Mailbox *GetMailboxByMailboxId(int64_t mailboxId);

	void MarkSend(Mailbox *pmb);
	void Send();
	void ClearDelMailboxs();
private:
	std::map<int, Mailbox *> m_fd2mb;
	std::map<int64_t, Mailbox *> m_id2mb;
	std::list<Mailbox *> m_delMailboxs;
	std::set<Mailbox *> m_sendMailboxs;
};
