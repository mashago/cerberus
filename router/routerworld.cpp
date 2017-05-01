
#include <string.h>
#include <string>
#include "logger.h"
#include "mailbox.h"
#include "routerworld.h"

RouterWorld::RouterWorld() : World()
{
	// TestPluto();
}

RouterWorld::~RouterWorld()
{
}

void TestPluto()
{
	enum { BUFFER_SIZE = 1024,};
	Pluto *pu = new Pluto(BUFFER_SIZE); // will delete by mailbox

	pu->WriteInt(100);
	pu->WriteInt(200);
	// set content
	char tmp[100];
	int len = sprintf(tmp, "welcome %ld", time(NULL));
	LOG_DEBUG("tmp=%s, len=%d", tmp, len);
	pu->WriteString(tmp, len);

	// set head
	pu->SetMsgLen();
	pu->SetMsgId(1);

	// check string
	memset(tmp, 0, sizeof(tmp));
	pu->ResetCursor();
	int n1 = pu->ReadInt();
	int n2 = pu->ReadInt();
	LOG_DEBUG("n1=%d n2=%d", n1, n2);
	len = pu->ReadString(tmp);
	LOG_DEBUG("tmp=%s, len=%d", tmp, len);

	delete pu;
}

void ClientTestPluto(Pluto &u)
{
	Mailbox *pmb = u.GetMailbox();
	if (!pmb)
	{
		// local pluto
		return;
	}

	// new a pluto, and push into mailbox
	
	enum { BUFFER_SIZE = 1024,};
	Pluto *out = new Pluto(BUFFER_SIZE); // will delete by mailbox

	out->WriteInt(time(NULL));
	// set content
	char tmp[100];
	int len = sprintf(tmp, "welcome");
	LOG_DEBUG("tmp=%s, len=%d", tmp, len);
	out->WriteString(tmp, len);

	// set head
	out->SetMsgLen();
	out->SetMsgId(MSGID_TYPE::CLIENT_TEST);
	out->SetMailbox(pmb);

	/*
	// check string
	out->ResetCursor();
	int n = out->ReadInt();
	memset(tmp, 0, sizeof(tmp));
	len = out->ReadString(tmp);
	LOG_DEBUG("n=%d tmp=%s, len=%d", n, tmp, len);
	*/

	// push
	pmb->PushPluto(out);
}

int RouterWorld::HandlePluto(Pluto &u)
{
	u.Print();

	if (!CheckPluto(u))
	{
		return 0;
	}

	int msgId = u.GetMsgId();

	switch (msgId)
	{
		case MSGID_TYPE::CLIENT_TEST:
		{
			ClientTestPluto(u);
			break;
		}
	}


	return 0;
}

void RouterWorld::HandleDisconnect(Mailbox *pmb)
{
}

void RouterWorld::HandleConnectToSuccess(Mailbox *pmb)
{
}
