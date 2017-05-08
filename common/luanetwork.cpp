#include "logger.h"
#include "pluto.h"
#include "net_service.h"
#include "luanetwork.h"

LuaNetwork* LuaNetwork::Instance()
{
	static LuaNetwork *instance = new LuaNetwork();
	return instance;
}

/*
bool LuaNetwork::connect_to(const char* ip, int port, unsigned& out_session_id)
{
	out_session_id = INT_MAX;

	if (Engine::Net* net = NetMgr::get_single_instance()->get_default_net()){
		return net->connect_to(ip, port, out_session_id);
	}

	return false;
}
*/

/*
LuaNetwork::LuaNetwork()
	:_recv_data(_nullptr)
	, _recv_data_len(0)
	, _recv_msg_id(0)
	, _recv_session_id(INT_MAX)
	, _cur_read_data_len(0)
	, _send_data_buff_len(MSG_MIN_LEN)
	, _send_data_buff_msg_id(-1)
	,_recv_addition(0)
{
	memset(_send_data_buff, 0, sizeof(_send_data_buff));
}
*/

LuaNetwork::LuaNetwork() : m_recvPluto(nullptr), m_sendPluto(nullptr)
{
	m_sendPluto = new Pluto(MSGLEN_MAX);
}

LuaNetwork::~LuaNetwork()
{
	delete m_sendPluto;
}


void LuaNetwork::initSendPluto()
{
	m_sendPluto->ResetCursor();
}

void LuaNetwork::WriteMsgId(int msgId)
{
	m_sendPluto->SetMsgId(msgId);
}

void LuaNetwork::WriteByte(char val)
{
	m_sendPluto->WriteByte(val);
}

void LuaNetwork::WriteInt(int val)
{
	m_sendPluto->WriteInt(val);
}

void LuaNetwork::WriteFloat(float val)
{
	m_sendPluto->WriteFloat(val);
}

void LuaNetwork::WriteBool(bool val)
{
	m_sendPluto->WriteBool(val);
}

void LuaNetwork::WriteShort(short val)
{
	m_sendPluto->WriteShort(val);
}

void LuaNetwork::WriteInt64(int64_t val)
{
	m_sendPluto->WriteInt64(val);
}

void LuaNetwork::WriteString(const char* str, short len)
{
	m_sendPluto->WriteString(str, len);
}

bool LuaNetwork::Send(int mailboxId)
{
	Mailbox *pmb = m_net->GetMailbox(mailboxId);
	if (!pmb)
	{
		LOG_WARN("mail box null %d", mailboxId);
		return false;
	}

	// TODO check pluto size

	Pluto *pu = m_sendPluto->Clone();
	pu->SetMailbox(pmb);
	pmb->PushPluto(pu);

	return true;
}

void LuaNetwork::SetRecvPluto(Pluto *pu)
{
	m_recvPluto = pu;
}

int LuaNetwork::ReadMsgId()
{
	return m_recvPluto->GetMsgId();
}

char LuaNetwork::ReadByte()
{
	return m_recvPluto->ReadByte();
}

int LuaNetwork::ReadInt()
{
	return m_recvPluto->ReadByte();
}

float LuaNetwork::ReadFloat()
{
	return m_recvPluto->ReadFloat();
}

bool LuaNetwork::ReadBool()
{
	return m_recvPluto->ReadBool();
}

short LuaNetwork::ReadShort()
{
	return m_recvPluto->ReadShort();
}

int64_t LuaNetwork::ReadInt64()
{
	return m_recvPluto->ReadInt64();
}

short LuaNetwork::ReadString(char *out_val)
{
	return m_recvPluto->ReadString(out_val);
}

void LuaNetwork::CloseSocket(int mailboxId)
{
	// Engine::SessionMgr::get_single_instance()->close_session(session_id);
}

