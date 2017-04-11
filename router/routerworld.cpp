
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

void TestSendPluto(Pluto &u)
{
	if (!u.m_pmb)
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
	*(uint32_t *)ptr = htonl(u.GetMsgId());

	Pluto *p = new Pluto(msgLen); // will delete by mailbox
	p->m_pmb = u.m_pmb;
	memcpy(p->GetBuffer(), buffer, msgLen);
	// p->Print();

	u.m_pmb->PushPluto(p);

}

int RouterWorld::FromRpcCall(Pluto &u)
{
	u.Print();

	if (!CheckClientRpc(u))
	{
		return 0;
	}

	// do core logic here
	// TODO
	TestSendPluto(u);

	return 0;
}
