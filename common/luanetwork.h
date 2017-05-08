#pragma once

#include <stdint.h>
// #include "net_service.h"

class Pluto;
class NetService;

class LuaNetwork
{
public:
	static LuaNetwork *Instance();

	void SetNetService(NetService *net)
	{
		m_net = net;
	}

	// bool connect_to(const char* ip, int port, unsigned& out_session_id);
	void WriteMsgId(int msg_id);
	void WriteByte(char val);
	void WriteInt(int val);
	void WriteFloat(float val);
	void WriteBool(bool val);
	void WriteShort(short val);
	void WriteInt64(int64_t val);
	void WriteString(const char* str, short len);

	bool Send(int mailboxId);

	//当前可写字符的最大长度
	// int can_write_string_maxlen();

	void SetRecvPluto(Pluto *pu);
	int ReadMsgId();
	char ReadByte();
	int ReadInt();
	float ReadFloat();
	bool ReadBool();
	short ReadShort();
	int64_t ReadInt64();
	short ReadString(char *out_val);

	void CloseSocket(int mailboxId);

private:
	void initSendPluto();

	LuaNetwork();
	~LuaNetwork();

	Pluto *m_recvPluto;
	Pluto *m_sendPluto;

	NetService *m_net;
};
