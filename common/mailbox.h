
#ifndef __MAILBOX_H__
#define __MAILBOX_H__

extern "C"
{
#include <event2/bufferevent.h>
}
#include "pluto.h"

class MailBox
{
public:
	MailBox();
	~MailBox();

// private:
	Pluto *m_pluto;
	struct bufferevent *m_bev;

};

#endif
