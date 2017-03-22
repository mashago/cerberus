
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
	TestCommand *cmd = new TestCommand();
	cmd->m_data = std::string(input, len);

	return cmd;
	// return nullptr;
}
