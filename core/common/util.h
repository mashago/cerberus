
#pragma once

#ifdef _WIN32
#include <winsock2.h>
#include <Windows.h>
#else
#include <unistd.h>
#include <sys/time.h>
#endif
#include <time.h>
#include <memory>
#include <list>

// clear pointer container
template <typename TP, template <typename E, typename Alloc = std::allocator<E>> class TC>
void ClearContainer(TC<TP> &c)
{
	while (!c.empty())
	{
		auto iter = c.begin();
		delete *iter;
		*iter = nullptr;
		c.erase(iter);
	}
}

template <typename T>
class SwitchList
{
public:
	typedef std::list<T> NodeList;
	
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

	const NodeList & InList()
	{
		return *m_pInList;
	}

	const NodeList & OutList()
	{
		return *m_pOutList;
	}

private:
	NodeList m_list1;
	NodeList m_list2;
	NodeList *m_pInList = &m_list1;
	NodeList *m_pOutList = &m_list2;
};

#ifdef WIN32
inline void localtime_r(time_t *now_time, struct tm *detail)
{
	localtime_s(detail, now_time);
}

// http://blog.csdn.net/earbao/article/details/53260297
inline void gettimeofday(struct timeval *tp, void *ptr)
{
	uint64_t  intervals;
	FILETIME  ft;

	GetSystemTimeAsFileTime(&ft);

	/*
	* A file time is a 64-bit value that represents the number
	* of 100-nanosecond intervals that have elapsed since
	* January 1, 1601 12:00 A.M. UTC.
	*
	* Between January 1, 1970 (Epoch) and January 1, 1601 there were
	* 134744 days,
	* 11644473600 seconds or
	* 11644473600,000,000,0 100-nanosecond intervals.
	*
	* See also MSKB Q167296.
	*/

	intervals = ((uint64_t)ft.dwHighDateTime << 32) | ft.dwLowDateTime;
	intervals -= 116444736000000000;

	tp->tv_sec = (long)(intervals / 10000000);
	tp->tv_usec = (long)((intervals % 10000000) / 10);
}

// #define snprintf(buffer, count, format, ...) do {_snprintf(buffer, count-1, format, ##__VA_ARGS__); buffer[count-1] = '\0'; } while (false)
#define snprintf(buffer, count, format, ...) do {_snprintf_s(buffer, count, count-1, format, ##__VA_ARGS__);} while (false)

inline void sleep(int second)
{
	Sleep(second * 1000);
}

#endif
