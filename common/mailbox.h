
#ifndef __MAILBOX_H__
#define __MAILBOX_H__

#include "pluto.h"

class MailBox
{
public:
	MailBox();
	~MailBox();

private:
	Pluto *m_pluto;
};

#endif
