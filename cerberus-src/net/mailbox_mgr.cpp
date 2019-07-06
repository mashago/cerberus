
#include "logger.h"
#include "mailbox.h"
#include "mailbox_mgr.h"

Mailbox *MailboxMgr::NewMailbox(int fd)
{
	Mailbox *pmb = new Mailbox();
	if (!pmb)
	{
		return nullptr;
	}

	pmb->SetFd(fd);

	auto iter = m_fd2mb.lower_bound(fd);
	if (iter != m_fd2mb.end() && iter->first == fd)
	{
		// still has old mailbox
		Mailbox *oldmb = iter->second;
		if (oldmb != pmb)
		{
			delete oldmb;
			iter->second = pmb;
		}
		LOG_WARN("has old mailbox fd=%d", fd);
	}
	else
	{
		// normal logic, insert new mailbox
		m_fd2mb.insert(iter, std::make_pair(fd, pmb));
	}
	m_id2mb[pmb->GetMailboxId()] = pmb;

	return pmb;
}

void MailboxMgr::CloseMailbox(Mailbox *pmb)
{
	pmb->ClearBEV();

	// push to list, delete by tick
	pmb->SetDelete(true);
	m_fd2mb.erase(pmb->GetFd());
	m_id2mb.erase(pmb->GetMailboxId());
	m_delMailboxs.push_back(pmb);
	m_sendMailboxs.erase(pmb);
}

Mailbox *MailboxMgr::GetMailboxByFd(int fd)
{
	auto iter = m_fd2mb.find(fd);
	if (iter == m_fd2mb.end())
	{
		return nullptr;
	}
	return iter->second;
}

Mailbox *MailboxMgr::GetMailboxByMailboxId(int64_t mailboxId)
{
	auto iter = m_id2mb.find(mailboxId);
	if (iter == m_id2mb.end())
	{
		return nullptr;
	}
	return iter->second;
}

void MailboxMgr::MarkSend(Mailbox *pmb)
{
	m_sendMailboxs.insert(pmb);
}

void MailboxMgr::Send()
{
	// loop all mailbox, do send all
	std::list<Mailbox *> ls4del;
	for (auto iter = m_sendMailboxs.begin(); iter != m_sendMailboxs.end(); )
	{
		Mailbox *pmb = *iter;
		if (!pmb)
		{
			m_sendMailboxs.erase(iter++);	
			LOG_ERROR("mailbox nil");
			continue;
		}
		// LOG_DEBUG("mailboxId=%ld", pmb->GetMailboxId());

		int ret = pmb->SendAll();
		if (ret == -1)
		{
			// send error
			m_sendMailboxs.erase(iter++);	
			ls4del.push_back(pmb);
			LOG_ERROR("send error %ld", pmb->GetMailboxId());
			continue;
		}
		else if (ret == 1)
		{
			// send finish
			m_sendMailboxs.erase(iter++);	
			continue;
		}

		// send not finish, keep mailbox in set
		++iter;
	}

	// close error mailbox
	for (auto iter = ls4del.begin(); iter != ls4del.end(); iter++)
	{
		CloseMailbox(*iter);
	}
}

void MailboxMgr::ClearDelMailboxs()
{
	ClearContainer(m_delMailboxs);
}
