#include "pluto.h"
#include "luaserversocket.h"

LuaServerSocket* LuaServerSocket::Instance()
{
	static LuaServerSocket *instance = new LuaServerSocket();
	return instance;
}

/*
bool LuaServerSocket::connect_to(const char* ip, int port, unsigned& out_session_id)
{
	out_session_id = INT_MAX;

	if (Engine::Net* net = NetMgr::get_single_instance()->get_default_net()){
		return net->connect_to(ip, port, out_session_id);
	}

	return false;
}
*/

/*
LuaServerSocket::LuaServerSocket()
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

LuaServerSocket::LuaServerSocket() : m_recvPluto(nullptr), m_sendPluto(nullptr)
{
	m_sendPluto = new Pluto(MSGLEN_MAX);
}

LuaServerSocket::~LuaServerSocket()
{
	delete m_sendPluto;
}


void LuaServerSocket::initSendPluto()
{
	m_sendPluto->ResetCursor();
}

void LuaServerSocket::WriteMsgId(int msgId)
{
	m_sendPluto->SetMsgId(msgId);
}

void LuaServerSocket::WriteByte(char val)
{
	m_sendPluto->WriteByte(val);
}

void LuaServerSocket::WriteInt(int val)
{
	m_sendPluto->WriteInt(val);
}

void LuaServerSocket::WriteFloat(float val)
{
	m_sendPluto->WriteFloat(val);
}

void LuaServerSocket::WriteBool(bool val)
{
	m_sendPluto->WriteBool(val);
}

void LuaServerSocket::WriteShort(short val)
{
	m_sendPluto->WriteShort(val);
}

void LuaServerSocket::WriteInt64(int64_t val)
{
	m_sendPluto->WriteInt64(val);
}

void LuaServerSocket::WriteString(const char* str, short len)
{
	m_sendPluto->WriteString(str, len);
}

bool LuaServerSocket::Send(int mailboxId)
{
	return false;
	/*

	if (_send_data_buff_msg_id == INT_MIN){
		Engine::Log::log("send_data_buff Msg ID not set !!!");
		init_send_data_buf();
		return false;
	}

	if (_send_data_buff_len > MSG_MAX_SIZE){
		Engine::Log::log("send_data_buff key = %d, len = %d , LEN bigger than  MSG_MAX_SIZE !!!", _send_data_buff_msg_id, _send_data_buff_len);
		init_send_data_buf();
		return false;
	}

	//将前PKG_HEAD_LEN个字节设置为长度
	memcpy(_send_data_buff, &_send_data_buff_len, PKG_HEAD_LEN);

	bool ret = Engine::SessionMgr::get_single_instance()->send_msg(session_id, _send_data_buff, _send_data_buff_len);

	init_send_data_buf();

	return ret;
	*/
}

void LuaServerSocket::SetRecvPluto(Pluto *pu)
{
	m_recvPluto = pu;
}

int LuaServerSocket::ReadMsgId()
{
	return m_recvPluto->GetMsgId();
}

char LuaServerSocket::ReadByte()
{
	return m_recvPluto->ReadByte();
}

int LuaServerSocket::ReadInt()
{
	return m_recvPluto->ReadByte();
}

float LuaServerSocket::ReadFloat()
{
	return m_recvPluto->ReadFloat();
}

bool LuaServerSocket::ReadBool()
{
	return m_recvPluto->ReadBool();
}

short LuaServerSocket::ReadShort()
{
	return m_recvPluto->ReadShort();
}

int64_t LuaServerSocket::ReadInt64()
{
	return m_recvPluto->ReadInt64();
}

short LuaServerSocket::ReadString(char *out_val)
{
	return m_recvPluto->ReadString(out_val);
}

void LuaServerSocket::CloseSocket(int mailboxId)
{
	// Engine::SessionMgr::get_single_instance()->close_session(session_id);
}

