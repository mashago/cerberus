
#pragma once

#include <list>
#include <utility>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <memory>

template <typename T>
class SwitchList
{
public:
	typedef std::list<T> TaskList;
	
	SwitchList() {}
	~SwitchList() {}

	template <typename TT>
	void Push(TT &&task)
	{
		m_pInList->push_back(std::forward<TT>(task));
	}

	void Switch()
	{
		std::swap(m_pInList, m_pOutList);
	}

	void CleanOut()
	{
		m_pOutList->clear();
	}

	int GetInSize()
	{
		return m_pInList->size();
	}

	int GetOutSize()
	{
		return m_pOutList->size();
	}

	bool IsInEmpty()
	{
		return m_pInList->empty();
	}

	bool IsOutEmpty()
	{
		return m_pOutList->empty();
	}

	const TaskList & InList()
	{
		return *m_pInList;
	}

	const TaskList & OutList()
	{
		return *m_pOutList;
	}

private:
	TaskList m_list1;
	TaskList m_list2;
	TaskList *m_pInList = &m_list1;
	TaskList *m_pOutList = &m_list2;
};

struct EventNode
{
	int type;
	void *ptr;
};

class EventPipe
{
public:
	EventPipe() {};
	~EventPipe() {};

	void Push(EventNode node)
	{
		std::unique_lock<std::mutex> lock(m_mtx);
		m_eventList.Push(node);
		m_cv.notify_all();
	}

	const std::list<EventNode> & Pop()
	{
		Switch();
		return m_eventList.OutList();
	}

	void CleanOut()
	{
		m_eventList.CleanOut();
	}

private:

	SwitchList<EventNode> m_eventList;
	std::mutex m_mtx;
	std::condition_variable m_cv;

	void Switch()
	{
		std::unique_lock<std::mutex> lock(m_mtx);
		m_cv.wait(lock, [this](){ return !m_eventList.IsInEmpty(); });
		m_eventList.Switch();
	}
};
