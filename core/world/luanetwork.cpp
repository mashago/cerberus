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

int64_t LuaNetwork::ConnectTo(const char* ip, unsigned int port)
{
	return m_world->ConnectTo(ip, port);
}

void LuaNetwork::ResetSendPluto()
{
	m_sendPluto->ResetCursor();
}

bool LuaNetwork::Send(int64_t mailboxId)
{
	// no need to check pluto size, if over size, write will not success
	m_sendPluto->SetMsgLen();
	Pluto *pu = m_sendPluto->Clone();
	pu->SetMailboxId(mailboxId);
	m_world->SendPluto(pu);
	ResetSendPluto();

	return true;
}

bool LuaNetwork::Transfer()
{
	// copy recv pluto data to send pluto
	m_sendPluto->Copy(m_recvPluto);
	return true;
}

void LuaNetwork::SetRecvPluto(Pluto *pu)
{
	m_recvPluto = pu;
}

void LuaNetwork::CloseMailbox(int64_t mailboxId)
{
	m_world->CloseMailbox(mailboxId);
}

bool LuaNetwork::HttpRequest(const char *url, int64_t session_id, int request_type, const char *post_data, int post_data_len)
{
	return m_world->HttpRequest(url, session_id, request_type, post_data, post_data_len);
}

