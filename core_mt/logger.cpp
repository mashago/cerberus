

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

void _logcore(int type, const char *filename, const char *funcname, int linenum, const char *fmt, ...)
{
	time_t now_time = time(NULL);
	char time_buffer[50];
#ifdef WIN32
	// SYSTEMTIME sys_time;
	// GetLocalTime(&sys_time);
	// sprintf(time_buffer, "%02d:%02d:%02d", sys_time.wHour, sys_time.wMinute, sys_time.wSecond);
	// struct tm detail;
	// localtime_s(&detail, &now_time);
	// sprintf(time_buffer, "%02d:%02d:%02d", detail.tm_hour, detail.tm_min, detail.tm_sec);
#else
#endif
	struct tm detail;
	localtime_r(&now_time, &detail);
	sprintf(time_buffer, "%02d:%02d:%02d", detail.tm_hour, detail.tm_min, detail.tm_sec);


	enum {MAX_LOG_BUFFER_SIZE = 2048};
	char buffer[MAX_LOG_BUFFER_SIZE];

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

/*
void __log(const char *title, const char *fmt, va_list ap)
{
	enum {MAX_LOG_BUFFER_SIZE = 1024};
	char buffer[MAX_LOG_BUFFER_SIZE];
	vsnprintf(buffer, MAX_LOG_BUFFER_SIZE, fmt, ap);

	printf("%s %s\n", title, buffer);
}

void LogDebug(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	__log("DEBUG", fmt, ap);
	va_end(ap);
}

void LogInfo(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	__log("INFO", fmt, ap);
	va_end(ap);
}

void LogWarn(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	__log("WARN", fmt, ap);
	va_end(ap);
}

void LogError(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	__log("ERROR", fmt, ap);
	va_end(ap);
}
*/
