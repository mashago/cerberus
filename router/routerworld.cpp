
#include <string.h>
#include <string>
#include "logger.h"
#include "mailbox.h"
#include "routerworld.h"

RouterWorld::RouterWorld() : World()
{
}

RouterWorld::~RouterWorld()
{
}

void TestSendPluto(MailBox *pmb, int msgId)
{
	if (pmb)
	{
		// local pluto
		return;
	}

	// new a pluto, and push into mailbox
	
	enum { BUFFER_SIZE = 1024,};
	char buffer[BUFFER_SIZE];

	int msgLen = PLUTO_FILED_BEGIN_POS;
	char *ptr = buffer;
	ptr += PLUTO_FILED_BEGIN_POS;

	// set content
	msgLen += snprintf(ptr, BUFFER_SIZE-PLUTO_FILED_BEGIN_POS, "welcome %ld", time(NULL));

	// set head
	ptr = buffer;
	*(uint32_t *)ptr = htonl(msgLen);
	ptr += MSGLEN_HEAD;
	*(uint32_t *)ptr = htonl(msgId);

	Pluto *p = new Pluto(msgLen); // will delete by mailbox
	p->m_pmb = pmb;
	memcpy(p->GetBuffer(), buffer, msgLen);
	// p->Print();

	pmb->PushPluto(p);

}

int RouterWorld::HandlePluto(Pluto &u)
{
	u.Print();

	if (!CheckPluto(u))
	{
		return 0;
	}

	// do core logic here
	// TODO
	TestSendPluto(u.m_pmb, u.m_msgId);

	return 0;
}

void RouterWorld::HandleDisconnect(MailBox *pmb)
{
}

void RouterWorld::HandleConnectToSuccess(MailBox *pmb)
{
}
