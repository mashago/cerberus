#include "common.h"
#include "logger.h"
#include "pluto.h"
#include "luanetwork.h"
#include "luaworld.h"

LuaNetwork::LuaNetwork(LuaWorld *world) : m_recvPluto(nullptr), m_sendPluto(nullptr), m_world(world)
{
	m_sendPluto = new Pluto(MSGLEN_MAX);
}

LuaNetwork::~LuaNetwork()
{
	delete m_sendPluto;
}

void LuaNetwork::SetRecvPluto(Pluto *pu)
{
	m_recvPluto = pu;
}

int64_t LuaNetwork::ConnectTo(const char* ip, unsigned int port)
{
	return m_world->ConnectTo(ip, port);
}

bool LuaNetwork::Send(int64_t mailboxId)
{
	// no need to check pluto size, if over size, write will not success
	m_sendPluto->SetMsgLen();
	Pluto *pu = m_sendPluto->Clone();
	pu->SetMailboxId(mailboxId);
	m_world->SendPluto(pu);
	m_sendPluto->Cleanup();

	return true;
}

bool LuaNetwork::Transfer(int64_t mailboxId)
{
	// just clone from recv pluto and copy ext from send pluto
	Pluto *pu = m_recvPluto->Clone();
	pu->SetMailboxId(mailboxId);
	pu->WriteExt(m_sendPluto->ReadExt());
	m_world->SendPluto(pu);
	m_sendPluto->Cleanup();

	return true;
}

void LuaNetwork::CloseMailbox(int64_t mailboxId)
{
	m_world->CloseMailbox(mailboxId);
}

bool LuaNetwork::HttpRequest(const char *url, int64_t session_id, int request_type, const char *post_data, int post_data_len)
{
	return m_world->HttpRequest(url, session_id, request_type, post_data, post_data_len);
}

bool LuaNetwork::Listen(const char* ip, unsigned int port, int64_t session_id)
{
	return m_world->Listen(ip, port, session_id);
}

