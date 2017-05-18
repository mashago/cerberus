
#include <arpa/inet.h>
#include <string.h>
#include "testcommand.h"
#include "pluto.h"
#include "common.h"


std::string TestCommand::Pack() 
{
	Pluto u(1024);

	std::string str = "hello world";
	int str_len = strlen(str.c_str());

	u.WriteByte('a');
	u.WriteBool(true);
	u.WriteInt(time(NULL));
	u.WriteFloat(3.14);
	u.WriteShort(12);
	u.WriteInt64(123456789123);
	u.WriteString(str_len, str.c_str());

	// TestStruct
	u.WriteByte('b');
	u.WriteBool(false);
	u.WriteInt(time(NULL));
	u.WriteFloat(3.15);
	u.WriteShort(13);
	u.WriteInt64(987654321987);
	u.WriteString(str_len, str.c_str());

	// array
	u.WriteShort(2);
	u.WriteByte('c');
	u.WriteByte('d');

	u.WriteShort(2);
	u.WriteBool(true);
	u.WriteBool(false);

	u.WriteShort(2);
	u.WriteInt(123);
	u.WriteInt(456);

	u.WriteShort(2);
	u.WriteFloat(1.23);
	u.WriteFloat(3.45);

	u.WriteShort(2);
	u.WriteShort(77);
	u.WriteShort(88);

	u.WriteShort(2);
	u.WriteInt64(11111111111);
	u.WriteInt64(22222222222);

	u.WriteShort(2);
	u.WriteString(str_len, str.c_str());
	u.WriteString(str_len, str.c_str());

	/*
	// TestStruct array
	u.WriteShort(1);
	u.WriteByte('k');
	u.WriteBool(false);
	u.WriteInt(123);
	u.WriteFloat(3.45);
	u.WriteShort(14);
	u.WriteInt64(333333333333);
	u.WriteString(str_len, str.c_str());
	*/


	u.WriteMsgId(MSGID_TYPE::CLIENT_TEST);
	u.SetMsgLen();
	
	std::string msg(u.GetBuffer(), u.GetMsgLen());

	return msg;
}
