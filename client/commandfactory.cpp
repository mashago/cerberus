
extern "C"
{
#include <string.h>
}
#include <string>
#include <string>
#include "commandfactory.h"
#include "testcommand.h"

CommandFactory::CommandFactory()
{
}

CommandFactory * CommandFactory::Instance()
{
	static CommandFactory *ptr = new CommandFactory();
	return ptr;
}

Command * CommandFactory::CreateCommand(const char *input, int len)
{
	char cmd[100];
	int n;
	int ret = sscanf(input, "%s %n", cmd, &n);
	if (ret != 1)
	{
		return nullptr;
	}

	Command *ret_cmd = nullptr;
	if (!strcmp(cmd, "test"))
	{
		ret_cmd = new TestCommand(std::string(input+n, len-n));
	}

	return ret_cmd;
}
