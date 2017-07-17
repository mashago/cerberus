
#include <time.h>
#include <stdarg.h>
#include <stdio.h>
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
	struct tm detail;
	localtime_r(&now_time, &detail);
	char time_buffer[50];
	sprintf(time_buffer, "%02d:%02d:%02d", detail.tm_hour, detail.tm_min, detail.tm_sec);

	enum {MAX_LOG_BUFFER_SIZE = 2048};
	char buffer[MAX_LOG_BUFFER_SIZE];

	va_list ap;
	va_start(ap, fmt);
	vsnprintf(buffer, MAX_LOG_BUFFER_SIZE, fmt, ap);
	va_end(ap);

	// if (1) return;
	switch (type)
	{
		case LOG_TYPE_DEBUG:
		{
			printf("\033[0;32;32m");
			break;
		}
		case LOG_TYPE_INFO:
		{
			break;
		}
		case LOG_TYPE_WARN:
		{
			printf("\033[1;33m");
			break;
		}
		case LOG_TYPE_ERROR:
		{
			printf("\033[0;32;31m");
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
	printf("\033[m\n");
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
