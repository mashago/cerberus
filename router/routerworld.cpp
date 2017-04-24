
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

void TestSendPluto(Mailbox *pmb, int msgId)
{
	if (pmb)
	{
		// local pluto
		return;
	}

	// new a pluto, and push into mailbox
	
	enum { BUFFER_SIZE = 1024,};
	Pluto *pu = new Pluto(BUFFER_SIZE); // will delete by mailbox

	// set content
	char tmp[100];
	int len = sprintf(tmp, "welcome %ld", time(NULL));
	pu->WriteString(tmp, len);

	// set head
	pu->SetMsgLen();
	pu->SetMsgId(msgId);

	pu->SetMailbox(pmb);
	pu->Print();

	pmb->PushPluto(pu);

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
	TestSendPluto(u.GetMailbox(), u.GetMsgId());

	return 0;
}

void RouterWorld::HandleDisconnect(Mailbox *pmb)
{
}

void RouterWorld::HandleConnectToSuccess(Mailbox *pmb)
{
}
