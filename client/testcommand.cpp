
#include <arpa/inet.h>
#include <string.h>
#include "testcommand.h"
#include "pluto.h"
#include "common.h"


std::string TestCommand::Pack() 
{
	Pluto u(1024);
	u.WriteInt(time(NULL));
	u.WriteString(m_data.size(), m_data.c_str());
	u.WriteMsgId(MSGID_TYPE::CLIENT_TEST);
	u.SetMsgLen();
	
	std::string msg(u.GetBuffer(), u.GetMsgLen());

	return msg;
}
