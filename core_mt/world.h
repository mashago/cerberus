
#pragma once

#include "pluto.h"
#include "event_pipe.h"

class NetService;

class World
{
public:
	World();
	virtual ~World();

	void SetEventPipe(EventPipe *net2worldPipe, EventPipe *world2netPipe)
	{
		m_net2worldPipe = net2worldPipe;
		m_world2netPipe = world2netPipe;
	}

	virtual bool Init(int server_id, int server_type, const char *conf_file, const char * entry_file);

	virtual bool CheckPluto(Pluto &u);
	virtual int HandlePluto(Pluto &u) = 0;
	virtual void HandleDisconnect(Mailbox *pmb) = 0;
	virtual void HandleConnectToSuccess(Mailbox *pmb) = 0;
	virtual void HandleNewConnection(Mailbox *pmb);
	virtual void HandleStdin(const char *buffer, int len);
	virtual void HandleEvent() = 0;
	
protected:
	NetService *m_net;
	EventPipe *m_net2worldPipe;
	EventPipe *m_world2netPipe;
};

