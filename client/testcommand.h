
#ifndef __TESTCOMMAND_H__
#define __TESTCOMMAND_H__

#include <string>
#include "command.h"

class TestCommand : public Command
{
public:
	TestCommand() : Command() {}
	virtual ~TestCommand() {}
	virtual std::string Pack() override;

	std::string m_data;
};

#endif
