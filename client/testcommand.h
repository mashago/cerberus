
#ifndef __TESTCOMMAND_H__
#define __TESTCOMMAND_H__

#include <string>
#include "command.h"

class TestCommand : public Command
{
public:
	TestCommand() : Command() {}
	TestCommand(std::string &&data) : Command(), m_data(data) {}
	virtual ~TestCommand() {}
	virtual std::string Pack() override;

private:
	std::string m_data;
};

#endif
