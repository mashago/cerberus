
#pragma once

#include "pluto.h"

class EventPipe;
struct EventNode;

class World
{
public:
	World();
	virtual ~World();

	void SetEventPipe(EventPipe *net2worldPipe, EventPipe *world2netPipe);

	virtual bool Init(int server_id, int server_type, const char *conf_file, const char * entry_file);

	virtual void HandleNewConnection(int64_t mailboxId, int32_t connType) = 0;
	virtual void HandleConnectToSuccess(int64_t mailboxId) = 0;
	virtual void HandleDisconnect(int64_t mailboxId) = 0;
	virtual void HandleMsg(Pluto &u) = 0;
	virtual void HandleStdin(const char *buffer);
	virtual void HandleConnectToRet(int64_t index, int64_t mailboxId) = 0;

	void RecvEvent();
	void SendEvent(EventNode *node);
	
private:
	EventPipe *m_net2worldPipe;
	EventPipe *m_world2netPipe;

	void HandleEvent(const EventNode &node);
};

