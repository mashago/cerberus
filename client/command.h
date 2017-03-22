
#ifndef __COMMAND_H__
#define __COMMAND_H__

#include <string>

class Command
{
public:
	virtual ~Command() {}
	virtual std::string Pack() = 0;
protected:
	Command() {}
};

#endif

