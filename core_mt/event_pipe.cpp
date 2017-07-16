
#include "event_pipe.h"

EventPipe::EventPipe() {};
EventPipe::~EventPipe() {};

void EventPipe::Push(EventNode *node)
{
	std::unique_lock<std::mutex> lock(m_mtx);
	m_eventList.Push(node);
	m_cv.notify_all();
}

const std::list<EventNode *> & EventPipe::Pop()
{
	m_eventList.CleanOut();
	Switch();
	return m_eventList.OutList();
}

void EventPipe::Switch()
{
	std::unique_lock<std::mutex> lock(m_mtx);
	m_cv.wait(lock, [this](){ return !m_eventList.IsInEmpty(); });
	m_eventList.Switch();
}
