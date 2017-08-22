

#include <time.h>
#include <stdarg.h>
#include <stdio.h>
#include "util.h"
#include "logger.h"

static const char *tags[] =
{
	"NULL"
,	"DEBUG"
,	"INFO"
,	"WARN"
,	"ERROR"
};

void format_log_str(char *out_buffer, const int buffer_len, bool is_for_print, int type, const char *filename, const char *funcname, int linenum, const char *fmt, ...)
{
	out_buffer[0] = '\0';

	time_t now_time = time(NULL);
	char time_buffer[50];

	struct tm detail;
	localtime_r(&now_time, &detail);
	sprintf(time_buffer, "%02d:%02d:%02d", detail.tm_hour, detail.tm_min, detail.tm_sec);

	// enum {MAX_LOG_BUFFER_SIZE = 2048};
	const int MAX_LOG_BUFFER_SIZE = buffer_len - 100;
	if (MAX_LOG_BUFFER_SIZE < 1)
	{
		return;
	}
	char buffer[MAX_LOG_BUFFER_SIZE+1];

	va_list ap;
	va_start(ap, fmt);
	vsnprintf(buffer, MAX_LOG_BUFFER_SIZE, fmt, ap);
	va_end(ap);

	// if (1) return;

	
	char prefix_buffer[50] = {0};
	char tail_buffer[50] = {0};
	if (is_for_print)
	{
		switch (type)
		{
			case LOG_TYPE_DEBUG:
			{
#ifndef WIN32
				sprintf(prefix_buffer, "\033[0;32;32m");
#endif
				break;
			}
			case LOG_TYPE_INFO:
			{
				break;
			}
			case LOG_TYPE_WARN:
			{
#ifndef WIN32
				sprintf(prefix_buffer, "\033[1;33m");
#endif
				break;
			}
			case LOG_TYPE_ERROR:
			{
#ifndef WIN32
				sprintf(prefix_buffer, "\033[0;32;31m");
#endif
				break;
			}
		}
#ifndef WIN32
		sprintf(tail_buffer, "\033[m");
#endif
	}

	if (linenum != 0)
	{
		snprintf(out_buffer, buffer_len, "%s[%s] [%s] %s:%s[%d] : %s%s\n", prefix_buffer, tags[type], time_buffer, filename, funcname, linenum, buffer, tail_buffer);
	}
	else
	{
		snprintf(out_buffer, buffer_len, "%s[%s] [%s] : %s%s\n", prefix_buffer, tags[type], time_buffer, buffer, tail_buffer);
	}
}

void _logcore(int type, const char *filename, const char *funcname, int linenum, const char *fmt, ...)
{
	time_t now_time = time(NULL);
	char time_buffer[50];

	struct tm detail;
	localtime_r(&now_time, &detail);
	sprintf(time_buffer, "%02d:%02d:%02d", detail.tm_hour, detail.tm_min, detail.tm_sec);

	enum {MAX_LOG_BUFFER_SIZE = 2048};
	char buffer[MAX_LOG_BUFFER_SIZE+1];

	va_list ap;
	va_start(ap, fmt);
	vsnprintf(buffer, MAX_LOG_BUFFER_SIZE, fmt, ap);
	va_end(ap);

	// if (1) return;

#ifdef _WIN32
	HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
	WORD wOldColorAttrs;
	CONSOLE_SCREEN_BUFFER_INFO csbiInfo;

	// save the current color  
	GetConsoleScreenBufferInfo(h, &csbiInfo);
	wOldColorAttrs = csbiInfo.wAttributes;
#endif

	switch (type)
	{
		case LOG_TYPE_DEBUG:
		{
#ifdef WIN32
			SetConsoleTextAttribute(h, FOREGROUND_GREEN | FOREGROUND_INTENSITY); // green
#else
			printf("\033[0;32;32m");
#endif
			break;
		}
		case LOG_TYPE_INFO:
		{
			break;
		}
		case LOG_TYPE_WARN:
		{
#ifdef WIN32
			SetConsoleTextAttribute(h, FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY); // yellow
#else
			printf("\033[1;33m");
#endif
			break;
		}
		case LOG_TYPE_ERROR:
		{
#ifdef WIN32
			SetConsoleTextAttribute(h, FOREGROUND_RED | FOREGROUND_INTENSITY); // red
#else
			printf("\033[0;32;31m");
#endif
			break;
		}
	}
	if (linenum != 0)
	{
		printf("[%s] [%s] %s:%s[%d] : %s", tags[type], time_buffer, filename, funcname, linenum, buffer);
	}
	else
	{
		printf("[%s] [%s] : %s", tags[type], time_buffer, buffer);
	}
#ifdef WIN32
	// Restore the original color  
	SetConsoleTextAttribute(h, wOldColorAttrs);
	printf("\n");
#else
	printf("\033[m\n");
#endif
}

///////////////////////////////////////////

LogPipe::LogPipe() {};
LogPipe::~LogPipe() {};

void LogPipe::Push(const char *buffer)
{
	std::unique_lock<std::mutex> lock(m_mtx);
	m_eventList.Push(buffer);
	m_cv.notify_all();
}

const std::list<const char *> & LogPipe::Pop()
{
	m_eventList.CleanOut();
	Switch();
	return m_eventList.OutList();
}

void LogPipe::Switch()
{
	std::unique_lock<std::mutex> lock(m_mtx);
	m_cv.wait(lock, [this](){ return !m_eventList.IsInEmpty(); });
	m_eventList.Switch();
}

////////////

Logger * Logger::Instance()
{
	static Logger *instance = new Logger();
	return instance;
}

void Logger::Init(const char *log_file_name)
{
	m_logFileName = log_file_name;
}

Logger::Logger() {}
Logger::~Logger() {}

void Logger::SendLog(int type, const char *filename, const char *funcname, int linenum, const char *fmt, ...)
{
	// 1. new log buffer
	// 2. init time buffer
	// 3. init content buffer
	// 4. init color prefix and tail
	// 5. sprintf log
	// 6. push
	
	enum {MAX_LOG_SIZE = 2048, MAX_LOG_CONTENT_SIZE = MAX_LOG_SIZE - 100};
	char *log_buffer = new char[MAX_LOG_SIZE+1];
	log_buffer[0] = '\0';

	time_t now_time = time(NULL);
	char time_buffer[50];

	struct tm detail;
	localtime_r(&now_time, &detail);
	sprintf(time_buffer, "%02d:%02d:%02d", detail.tm_hour, detail.tm_min, detail.tm_sec);

	char content_buffer[MAX_LOG_CONTENT_SIZE+1];
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(content_buffer, MAX_LOG_CONTENT_SIZE, fmt, ap);
	va_end(ap);

	
	char prefix_buffer[50] = {0};
	char tail_buffer[50] = {0};
	if (m_logFileName == "")
	{
		switch (type)
		{
			case LOG_TYPE_DEBUG:
			{
#ifndef WIN32
				sprintf(prefix_buffer, "\033[0;32;32m");
#endif
				break;
			}
			case LOG_TYPE_INFO:
			{
				break;
			}
			case LOG_TYPE_WARN:
			{
#ifndef WIN32
				sprintf(prefix_buffer, "\033[1;33m");
#endif
				break;
			}
			case LOG_TYPE_ERROR:
			{
#ifndef WIN32
				sprintf(prefix_buffer, "\033[0;32;31m");
#endif
				break;
			}
		}
#ifndef WIN32
		sprintf(tail_buffer, "\033[m");
#endif
	}

	if (linenum != 0)
	{
		snprintf(log_buffer, MAX_LOG_SIZE, "%s[%s] [%s] %s:%s[%d] : %s%s\n", prefix_buffer, tags[type], time_buffer, filename, funcname, linenum, content_buffer, tail_buffer);
	}
	else
	{
		snprintf(log_buffer, MAX_LOG_SIZE, "%s[%s] [%s] : %s%s\n", prefix_buffer, tags[type], time_buffer, content_buffer, tail_buffer);
	}

	m_logPipe.Push(log_buffer);
}

void Logger::RecvLog()
{
	auto log_list = m_logPipe.Pop();
	for (auto iter = log_list.begin(); iter != log_list.end(); ++iter)
	{
		// TODO printf or write into file
		printf(*iter);	
		delete [] (*iter);
	}
}
