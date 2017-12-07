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

void LuaNetwork::initSendPluto()
{
	m_sendPluto->ResetCursor();
}

void LuaNetwork::WriteMsgId(int msgId)
{
	m_sendPluto->WriteMsgId(msgId);
}

void LuaNetwork::WriteExt(int ext)
{
	m_sendPluto->WriteExt(ext);
}

bool LuaNetwork::WriteByte(char val)
{
	return m_sendPluto->WriteByte(val);
}

bool LuaNetwork::WriteInt(int val)
{
	return m_sendPluto->WriteInt(val);
}

bool LuaNetwork::WriteFloat(float val)
{
	return m_sendPluto->WriteFloat(val);
}

bool LuaNetwork::WriteBool(bool val)
{
	return m_sendPluto->WriteBool(val);
}

bool LuaNetwork::WriteShort(short val)
{
	return m_sendPluto->WriteShort(val);
}

bool LuaNetwork::WriteInt64(int64_t val)
{
	return m_sendPluto->WriteInt64(val);
}

bool LuaNetwork::WriteString(int len, const char* str)
{
	return m_sendPluto->WriteString(len, str);
}

bool LuaNetwork::Send(int64_t mailboxId)
{
	// no need to check pluto size, if over size, write will not success
	m_sendPluto->SetMsgLen();
	Pluto *pu = m_sendPluto->Clone();
	pu->SetMailboxId(mailboxId);
	m_world->SendPluto(pu);

	initSendPluto();

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

int LuaNetwork::ReadMsgId()
{
	return m_recvPluto->ReadMsgId();
}

int LuaNetwork::ReadExt()
{
	return m_recvPluto->ReadExt();
}

bool LuaNetwork::ReadByte(char &out_val)
{
	return m_recvPluto->ReadByte(out_val);
}

bool LuaNetwork::ReadInt(int &out_val)
{
	return m_recvPluto->ReadInt(out_val);
}

bool LuaNetwork::ReadFloat(float &out_val)
{
	return m_recvPluto->ReadFloat(out_val);
}

bool LuaNetwork::ReadBool(bool &out_val)
{
	return m_recvPluto->ReadBool(out_val);
}

bool LuaNetwork::ReadShort(short &out_val)
{
	return m_recvPluto->ReadShort(out_val);
}

bool LuaNetwork::ReadInt64(int64_t &out_val)
{
	return m_recvPluto->ReadInt64(out_val);
}

bool LuaNetwork::ReadString(int &out_len, char *out_val)
{
	return m_recvPluto->ReadString(out_len, out_val);
}

void LuaNetwork::CloseMailbox(int64_t mailboxId)
{
	m_world->CloseMailbox(mailboxId);
}

bool LuaNetwork::HttpRequest(const char *url, int64_t session_id, int request_type, const char *post_data, int post_data_len)
{
	return m_world->HttpRequest(url, session_id, request_type, post_data, post_data_len);
}

