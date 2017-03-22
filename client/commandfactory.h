
#ifndef __COMMANDFACTORY_H__
#define __COMMANDFACTORY_H__
#include "command.h"

class CommandFactory
{
public:
	static CommandFactory *Instance();
	Command *CreateCommand(const char *input, int len);
private:
	CommandFactory();
};

#endif
