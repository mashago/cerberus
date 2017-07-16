
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

	virtual void HandleNewConnection(int64_t mailboxId, int32_t connType) = 0;
	virtual void HandleConnectToSuccess(int64_t mailboxId) = 0;
	virtual void HandleDisconnect(int64_t mailboxId) = 0;
	virtual void HandlePluto(Pluto &u) = 0;
	virtual void HandleStdin(const char *buffer);

	void HandleEvent(const EventNode &node);

	void RecvEvent();
	void SendEvent(EventNode *node);
	
protected:
	NetService *m_net;
	EventPipe *m_net2worldPipe;
	EventPipe *m_world2netPipe;
};

