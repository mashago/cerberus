

#include <time.h>
#include <stdarg.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <sys/stat.h>
#ifdef WIN32
#include <direct.h>
#endif
#include "util.h"
#include "logger.h"

static const char *tags[] =
{
	"[NULL]"
,	"[DEBUG]"
,	"[INFO]"
,	"[WARN]"
,	"[ERROR]"
};


#if (NOT_USE_LOGGER == 1)

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
		printf("%s [%s] %s:%s[%d] : %s", tags[type], time_buffer, filename, funcname, linenum, buffer);
	}
	else
	{
		printf("%s [%s] : %s", tags[type], time_buffer, buffer);
	}
#ifdef WIN32
	// Restore the original color  
	SetConsoleTextAttribute(h, wOldColorAttrs);
	printf("\n");
#else
	printf("\033[m\n");
#endif
}

#else

LogPipe::LogPipe() {}
LogPipe::~LogPipe() {}

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

Logger::Logger() : m_isRunning(false), m_isWriteLog(false), m_isPrintLog(false) {}
Logger::~Logger() {}

Logger * Logger::Instance()
{
	static Logger *instance = new Logger();
	return instance;
}

void Logger::Init(const char *log_file_name, bool is_print_log)
{
	if (m_isRunning)
	{
		return;
	}

	// mkdir log
	
#ifdef WIN32
	_mkdir("../log");
#else
	mkdir("../log", S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
#endif

	m_isWriteLog = strcmp(log_file_name, "") != 0;
	m_logFileName = std::string("../log/") + log_file_name;
	m_isPrintLog = is_print_log;

	auto log_run = [this]()
	{
		while (this->m_isRunning)
		{
			this->RecvLog();	
		}
		printf("log stop loop\n");
		// handle last log
		this->m_logPipe.Push(NULL);
		this->RecvLog();
	};
	m_isRunning = true;
	m_logThread = std::thread(log_run);
}

void Logger::SendLog(int type, const char *filename, const char *funcname, int linenum, const char *fmt, ...)
{
	if (!m_isRunning)
	{
		return;
	}

	// 1. new log buffer
	// 2. init time buffer
	// 3. init content buffer
	// 4. sprintf log
	// 5. push
	
	enum {MAX_LOG_SIZE = 2048, MAX_LOG_CONTENT_SIZE = MAX_LOG_SIZE - 200};
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

	
	if (linenum != 0)
	{
		snprintf(log_buffer, MAX_LOG_SIZE, "%s [%s] %s:%s[%d] : %s", tags[type], time_buffer, filename, funcname, linenum, content_buffer);
	}
	else
	{
		snprintf(log_buffer, MAX_LOG_SIZE, "%s [%s] : %s", tags[type], time_buffer, content_buffer);
	}

	m_logPipe.Push(log_buffer);
}

void Logger::SendLogStr(int type, const char *filename, const char *funcname, int linenum, const char *content_buffer)
{
	if (!m_isRunning)
	{
		return;
	}

	// 1. new log buffer
	// 2. sprintf log
	// 3. push
	
	enum {MAX_HEADER_SIZE = 200};
	int content_len = strlen(content_buffer);
	int MAX_LOG_SIZE = MAX_HEADER_SIZE + content_len;
	char *log_buffer = new char[MAX_LOG_SIZE];

	time_t now_time = time(NULL);
	char time_buffer[50];

	struct tm detail;
	localtime_r(&now_time, &detail);
	sprintf(time_buffer, "%02d:%02d:%02d", detail.tm_hour, detail.tm_min, detail.tm_sec);
	
	if (linenum != 0)
	{
		snprintf(log_buffer, MAX_LOG_SIZE, "%s [%s] %s:%s[%d] : %s", tags[type], time_buffer, filename, funcname, linenum, content_buffer);
	}
	else
	{
		snprintf(log_buffer, MAX_LOG_SIZE, "%s [%s] : %s", tags[type], time_buffer, content_buffer);
	}

	m_logPipe.Push(log_buffer);
}

void Logger::RecvLog()
{
	auto log_list = m_logPipe.Pop();
	if (log_list.empty())
	{
		return;
	}

	FILE *pfile = NULL;
	std::string file_name = m_logFileName + ".txt";
	if (m_isWriteLog)
	{
		pfile = fopen(file_name.c_str(), "a");
	}
	for (auto iter = log_list.begin(); iter != log_list.end(); ++iter)
	{
		if (!*iter)
		{
			continue;
		}
		if (m_isPrintLog)
		{
			PrintLog(*iter);
		}
		if (pfile)
		{
			fwrite(*iter, strlen(*iter), 1, pfile);
			fwrite("\n", 1, 1, pfile);
		}

		delete [] (*iter);
	}
	if (pfile)
	{
		fclose(pfile);
		// TODO shift log file
		ShiftLogFile();
	}
}

void Logger::ShiftLogFile()
{
	enum { MAX_LOG_FILE_SIZE = 102400000 }; 
	std::string file_name = m_logFileName + ".txt";

#ifdef WIN32
	struct _stat file_stat;
	if (_stat(file_name.c_str(), &file_stat) < 0)
#else
	struct stat file_stat;
	if (stat(file_name.c_str(), &file_stat) < 0)
#endif
	{
		perror("Logger::ShiftLogFile stat error");
		return;
	}

	// printf("file_stat.st_size=%lld\n", (long long)file_stat.st_size);

	if (file_stat.st_size < MAX_LOG_FILE_SIZE)
	{
		return;
	}

	// rename
	struct timeval tv;    
	gettimeofday(&tv, NULL);
	int64_t time_ms = (int64_t)(tv.tv_sec * 1000.0 + tv.tv_usec / 1000.0);
	std::string new_file_name = m_logFileName + "_" + std::to_string(time_ms) + ".txt";
	if (rename(file_name.c_str(), new_file_name.c_str()) < 0)
	{
		perror("Logger::ShiftLogFile rename error");
		return;
	}
}

void Logger::Stop()
{
	m_isRunning = false;
	m_logPipe.Push(NULL);
	m_logThread.join();
}

void Logger::PrintLog(const char *buffer)
{
	// add color by buffer prefix tag
#ifdef _WIN32
	HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
	WORD wOldColorAttrs;
	CONSOLE_SCREEN_BUFFER_INFO csbiInfo;

	// save the current color  
	GetConsoleScreenBufferInfo(h, &csbiInfo);
	wOldColorAttrs = csbiInfo.wAttributes;

	// check log level
	// [ERROR] [WARNING] [INFO] [DEBUG]
	auto set_color = [&h](const char *input, const char *prefix, WORD color)
	{
		int input_len = strlen(input);
		int prefix_len = strlen(prefix);
		if (input_len < prefix_len)
		{
			return false;
		}

		for (int i = 0; i < prefix_len; ++i)
		{
			if (*input++ != *prefix++)
			{
				return false;
			}
		}
		SetConsoleTextAttribute(h, color);

		return true;
	};

	// Set the new color  
	set_color(buffer, tags[LOG_TYPE_DEBUG], FOREGROUND_GREEN | FOREGROUND_INTENSITY); // green
	set_color(buffer, tags[LOG_TYPE_WARN], FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY); // yellow
	set_color(buffer, tags[LOG_TYPE_ERROR], FOREGROUND_RED | FOREGROUND_INTENSITY); // red

	printf("%s\n", buffer);

	// Restore the original color  
	SetConsoleTextAttribute(h, wOldColorAttrs);

#else

	char prefix_buffer[50] = {0};
	const char *tail_buffer = "\033[m";

	auto set_color = [&prefix_buffer](const char *input, const char *prefix, const char *color)
	{
		int input_len = strlen(input);
		int prefix_len = strlen(prefix);
		if (input_len < prefix_len)
		{
			return false;
		}

		for (int i = 0; i < prefix_len; ++i)
		{
			if (*input++ != *prefix++)
			{
				return false;
			}
		}
		sprintf(prefix_buffer, "%s", color);

		return true;
	};

	// Set the new color  
	set_color(buffer, tags[LOG_TYPE_DEBUG], "\033[0;32;32m");
	set_color(buffer, tags[LOG_TYPE_INFO], "\033[m");
	set_color(buffer, tags[LOG_TYPE_WARN], "\033[1;33m");
	set_color(buffer, tags[LOG_TYPE_ERROR], "\033[0;32;31m");

	printf("%s%s%s\n", prefix_buffer, buffer, tail_buffer);

#endif
}

#endif
