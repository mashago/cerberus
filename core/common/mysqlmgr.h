
#pragma once

#include <stdint.h>
#include <mysql.h>
#include <string>

class MysqlMgr
{
public:
	MysqlMgr();
	~MysqlMgr();

	// 0 for success
	int Connect(std::string host, int port, std::string username, std::string password, std::string db_name, std::string charset = "utf8");
	void Close();

	// out_buffer size should be 2 * in_buffer size + 1
	int EscapeString(char *out_buffer, const char *in_buffer, int len);

	// 0 as success, else as error
	int Select(const char *sql, int len);
	// return affect row, -1 as error
	int Change(const char *sql, int len);

	int FieldCount();
	int NumRows();
	// int AffectedRows();
	int64_t GetInsertId();
	
	MYSQL_FIELD * FetchField();
	MYSQL_ROW FetchRow();

	int GetErrno();
	const char * GetError();

private:
	std::string m_host;
	int m_port;
	std::string m_username;
	std::string m_password;
	std::string m_db_name;
	std::string m_charset;

	MYSQL *conn;
	MYSQL_RES *m_result;
	int m_err;

	int Reconnect();
	MYSQL * CoreConnect();
	int CoreQuery(const char *sql, int len, bool is_select);
	void CleanResult();
};

