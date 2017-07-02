
#include <arpa/inet.h>
#include <string.h>
#include "testcommand.h"
#include "pluto.h"
#include "common.h"


std::string TestCommand::Pack() 
{
	Pluto u(1024);

	std::string str = "hello world";

	u.WriteByte('a');
	u.WriteBool(true);
	u.WriteInt(time(NULL));
	u.WriteFloat(3.14);
	u.WriteShort(12);
	u.WriteInt64(123456789123);
	u.WriteString(str.size(), str.c_str());

	// TestStruct
	u.WriteByte('b');
	u.WriteBool(false);
	u.WriteInt(time(NULL));
	u.WriteFloat(3.15);
	u.WriteShort(13);
	u.WriteInt64(987654321987);
	str = "hello world 2";
	u.WriteString(str.size(), str.c_str());

	// array
	u.WriteInt(2);
	u.WriteByte('c');
	u.WriteByte('d');

	u.WriteInt(2);
	u.WriteBool(true);
	u.WriteBool(false);

	u.WriteInt(2);
	u.WriteInt(123);
	u.WriteInt(456);

	u.WriteInt(2);
	u.WriteFloat(1.23);
	u.WriteFloat(3.45);

	u.WriteInt(2);
	u.WriteShort(77);
	u.WriteShort(88);

	u.WriteInt(2);
	u.WriteInt64(11111111111);
	u.WriteInt64(22222222222);

	u.WriteInt(2);
	str = "hello world 3";
	u.WriteString(str.size(), str.c_str());
	str = "hello world 4";
	u.WriteString(str.size(), str.c_str());

	// TestStruct array
	u.WriteInt(2);

	u.WriteByte('x');
	u.WriteBool(false);
	u.WriteInt(123);
	u.WriteFloat(3.45);
	u.WriteShort(32766);
	u.WriteInt64(333333333333);
	str = "hello world 5";
	u.WriteString(str.size(), str.c_str());

	u.WriteByte('y');
	u.WriteBool(true);
	u.WriteInt(456);
	u.WriteFloat(6.78);
	u.WriteShort(32767);
	u.WriteInt64(444444444444);
	str = "hello world 6";
	u.WriteString(str.size(), str.c_str());


	u.WriteMsgId(MSGID_TYPE::CLIENT_TEST);
	u.WriteExt(0);
	u.SetMsgLen();
	
	std::string msg(u.GetBuffer(), u.GetMsgLen());

	return msg;
}
