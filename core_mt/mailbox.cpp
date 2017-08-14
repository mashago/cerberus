
extern "C"
{
#include <stddef.h>
#include <string.h>
#include <event2/buffer.h>
#include <event2/bufferevent.h>
}
#include "logger.h"
#include "util.h"
#include "mailbox.h"
#include "pluto.h"

static int64_t _get_mailbox_id()
{
	static int64_t mailboxId = 1;
	return mailboxId++;
}

Mailbox::Mailbox(E_CONN_TYPE type) : m_fdType(type), m_fd(-1), m_mailboxId(-1), m_recvPluto(nullptr), m_bev(nullptr), m_bDeleteFlag(false), m_sendPos(0)
{
	m_mailboxId = _get_mailbox_id();
}

Mailbox::~Mailbox()
{
	// delete recv pluto
	if (m_recvPluto)
	{
		delete m_recvPluto;
	}

	// delete send pluto
	ClearContainer(m_tobeSend);
}

void Mailbox::PushSendPluto(Pluto *u)
{
	m_tobeSend.push_back(u);
}

// return -1 as error
// return 1 as send finish
// return 0 as still has data not send
int Mailbox::SendAll()
{
	// LOG_DEBUG("m_tobeSend.size=%d", m_tobeSend.size());

	if (!m_bev)
	{
		return 1;
	}

	if (m_tobeSend.empty())
	{
		return 1;
	}

	struct evbuffer *output = bufferevent_get_output(m_bev);
	while (!m_tobeSend.empty())
	{
		// send pluto
		Pluto *u = m_tobeSend.front();
		int nSendWant = u->GetMsgLen() - m_sendPos;

		struct evbuffer_iovec v[1]; // the vector struct to access evbuffer directly, without memory copy
		// reserve space
		int res = evbuffer_reserve_space(output, nSendWant, v, 1);
		const size_t iov_len = v[0].iov_len; // iov_len may not equal to reserve num
		if (res <= 0 || iov_len == 0)
		{
			LOG_ERROR("evbuffer_reserve_space fail m_fd=%d nSendWant=%d res=%d", m_fd, nSendWant, res);
			return -1;
		}

		// reset iov_len to send buffer size, and copy buffer to iov
		char *buffer = (char *)v[0].iov_base;
		int nSendCan = nSendWant <= (int)iov_len ? nSendWant : iov_len;
		memcpy(buffer, u->GetBuffer()+m_sendPos, nSendCan);
		v[0].iov_len = nSendCan;

		// commit space
		if (evbuffer_commit_space(output, v, 1) != 0)
		{
			LOG_ERROR("evbuffer_commit_space fail m_fd=%d", m_fd);
			return -1;
		}

		// check if all data send
		if (nSendCan != nSendWant)
		{
			// still has data in pluto 
			// send block, do it later
			// update send pos
			m_sendPos += nSendCan;
			return 0;
		}

		// pluto send done, do clean
		m_sendPos = 0;
		m_tobeSend.pop_front();
		delete u; // world new, net delete
	}

	if (!m_tobeSend.empty())
	{
		return 0;
	}

	return 1;
}
