
extern "C"
{
#include <stddef.h>
}
#include "mailbox.h"

MailBox::MailBox(EFDTYPE type) : m_fdType(type), m_pluto(nullptr), m_bev(nullptr), m_bDeleteFlag(false)
{
}

MailBox::~MailBox()
{
	if (m_pluto)
	{
		delete m_pluto;
	}
}
