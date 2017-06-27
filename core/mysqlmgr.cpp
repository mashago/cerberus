
#include <stdio.h>
#include <unistd.h>
#include "mysqlmgr.h"

MysqlMgr::MysqlMgr() 
: host(""), port(0), username(""), password(""), db_name(""), charset("")
, conn(NULL), result(NULL), err(0)
{
}

MysqlMgr::~MysqlMgr()
{
}

MYSQL * MysqlMgr::CoreConnect()
{
	// 1.do mysql_init()
	// 2.set mysql options
	// 3.do mysql_real_connect()
	
	MYSQL *new_conn = NULL;
	new_conn = mysql_init(NULL);  // NULL ?
	if (new_conn == NULL)
	{
		return NULL;
	}

	mysql_options(new_conn, MYSQL_SET_CHARSET_NAME, charset.c_str());

	MYSQL *ret_conn;
	ret_conn = mysql_real_connect(new_conn, host.c_str(), username.c_str(), password.c_str(), db_name.c_str(), port, NULL, 0);
	if (ret_conn == NULL)
	{
		err = mysql_errno(new_conn);
		mysql_close(new_conn);
		return NULL;
	}

	return new_conn;
}

int MysqlMgr::Connect(std::string host, int port, std::string username, std::string password, std::string db_name, std::string charset)
{
	this->host = host;
	this->port = port;
	this->username = username;
	this->password = password;
	this->db_name = db_name;
	this->charset = charset;

	if (conn != NULL)
	{
		return -1;
	}
	conn = CoreConnect();
	if (conn == NULL)
	{
		return -2;
	}
	return 0;
}

int MysqlMgr::Close()
{
	if (conn != NULL)
	{
		CleanResult();
		mysql_close(conn);
		conn = NULL;
	}
	return 0;
}

int MysqlMgr::Reconnect()
{
	MYSQL *new_conn = NULL;
	new_conn = CoreConnect();
	if (new_conn == NULL)
	{
		return -1;
	}
	Close();
	conn = new_conn;
	return 0;
}

int MysqlMgr::EscapeString(char *out_buffer, const char *in_buffer, int len)
{
	return mysql_real_escape_string(conn, out_buffer, in_buffer, len);
}

int MysqlMgr::Query(const char *sql, int len)
{
	// 1.do mysql_real_query
	// 2.clean mysql result
	// 3.do mysql_store_result, event sql is not a select
	// 4.if error is disconnect, Reconnect and try again
	
	int ret = 0;
	int reconn_count = 0;
	do
	{
		if (conn != NULL)
		{
			ret = mysql_real_query(conn, sql, len);
			if (ret == 0)
			{
				CleanResult();
				result = mysql_store_result(conn); // when exec is NOT select, this call is ok
				return ret;
			}
		}

		ret = -1;

		err = 8888; // 8888 for connect null

		if (conn != NULL)
		{
			err = mysql_errno(conn);
		}

		if (err == 2013 || err == 2006 || err == 8888)
		{
			printf("Query:disconnect errno=%d\n", err);
			sleep(1);
			Reconnect();
			reconn_count++;
		}
		else
		{
			// execute error
			return ret;
		}
	}
	while (reconn_count < 3);

	return ret;
}

int MysqlMgr::FieldCount()
{
	if (conn == NULL)
	{
		return -1;
	}

	return mysql_field_count(conn);
}

int MysqlMgr::NumRows()
{
	if (conn == NULL)
	{
		return -1;
	}

	if (result == NULL)
	{
		return -1;
	}

	return mysql_num_rows(result);
}

int MysqlMgr::AffectedRows()
{
	if (conn == NULL)
	{
		return -1;
	}

	return mysql_affected_rows(conn);
}

MYSQL_ROW MysqlMgr::FetchRow()
{
	MYSQL_ROW row = NULL;
	if (conn == NULL)
	{
		return row;
	}

	if (result == NULL)
	{
		return row;
	}

	row = mysql_fetch_row(result);

	return row;
}

void MysqlMgr::CleanResult()
{
	err = 0;

	if (result != NULL)
	{
		mysql_free_result(result);
		result = NULL;
	}

	while(!mysql_next_result(conn))
	{
		result = mysql_store_result(conn);
		mysql_free_result(result);
	} 

	result = NULL;
}

int MysqlMgr::GetErr()
{
	return err;
}

