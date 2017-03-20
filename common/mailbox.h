
#ifndef __MAILBOX_H__
#define __MAILBOX_H__

extern "C"
{
#include <event2/bufferevent.h>
}
#include "common.h"
#include "pluto.h"

class MailBox
{
public:
	MailBox(EFDTYPE type);
	~MailBox();

	void SetFd(int fd)
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

	int SendAll();

// private:
	EFDTYPE m_fdType;
	int m_fd;
	Pluto *m_pluto;
	struct bufferevent *m_bev;
	bool m_bDeleteFlag;

};

#endif
