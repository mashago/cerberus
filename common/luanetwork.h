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
	bool WriteByte(char val);
	bool WriteInt(int val);
	bool WriteFloat(float val);
	bool WriteBool(bool val);
	bool WriteShort(short val);
	bool WriteInt64(int64_t val);
	bool WriteString(short len, const char* str);

	bool Send(int mailboxId);

	//当前可写字符的最大长度
	// int can_write_string_maxlen();

	void SetRecvPluto(Pluto *pu);
	int  ReadMsgId();
	bool ReadByte(char &out_val);
	bool ReadInt(int &out_val);
	bool ReadFloat(float &out_val);
	bool ReadBool(bool &out_val);
	bool ReadShort(short &out_val);
	bool ReadInt64(int64_t &out_val);
	bool ReadString(short &out_len, char *out_val);

	void CloseSocket(int mailboxId);

private:
	void initSendPluto();

	LuaNetwork();
	~LuaNetwork();

	Pluto *m_recvPluto;
	Pluto *m_sendPluto;

	NetService *m_net;
};
