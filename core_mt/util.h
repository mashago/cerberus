
#pragma once

#ifdef _WIN32
#include <winsock2.h>
#include <Windows.h>
#else
#include <unistd.h>
#endif
#include <time.h>
#include <memory>

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

#ifdef WIN32
void localtime_r(time_t *now_time, struct tm *detail)
{
	localtime_s(detail, now_time);
}

// http://blog.csdn.net/earbao/article/details/53260297
void gettimeofday(struct timeval *tp, void *ptr)
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
#endif

inline void sleep_second(int second)
{
#ifdef WIN32
	Sleep(second * 1000);
#else
	sleep(1);
#endif
}
