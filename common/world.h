
#ifndef __WORLD_H__
#define __WORLD_H__

#include "pluto.h"

class NetService;

class World
{
public:
	World();
	virtual ~World();

	void SetNetService(NetService *net)
	{
		m_net = net;
	}

	NetService * GetNetService()
	{
		return m_net;
	}
	virtual bool Init(int server_id, int server_type, const char * entry_file_name);

	virtual bool CheckPluto(Pluto &u);
	virtual int HandlePluto(Pluto &u) = 0;
	virtual void HandleDisconnect(Mailbox *pmb) = 0;
	virtual void HandleConnectToSuccess(Mailbox *pmb) = 0;
protected:
	NetService *m_net;
};

#endif
