
// #include <unistd.h>
#include <set>
#include <string>

#include "util.h"
#include "common.h"
#include "logger.h"
#include "tinyxml2.h"
#include "mysqlmgr.h"
#ifndef _SINGLE_THREAD_CORE
#include "event_pipe.h"
#endif

// test xml config
int test0()
{
	const char *conf_file = "../conf/server_conf_demo.xml";

	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		LOG_ERROR("load conf error %s", conf_file);
		return -1;
	}

	tinyxml2::XMLElement *root = doc.FirstChildElement();
	int server_id = root->IntAttribute("id");
	int server_type = root->IntAttribute("type");
	const char *ip = (char*)root->Attribute("ip");
	int port = root->IntAttribute("port");
	const char *entry_file = (char*)root->Attribute("file");
	LOG_DEBUG("server_id=%d server_type=%d ip=%s port=%d entry_file=%s"
	, server_id, server_type, ip, port, entry_file);

	std::set<std::string> trustIpSet;
	tinyxml2::XMLElement *trust_ip = root->FirstChildElement("trust_ip");
	if (trust_ip)
	{
		tinyxml2::XMLElement *addr = trust_ip->FirstChildElement("address");
		while (addr)
		{
			const char *ip = (char *)addr->Attribute("ip");
			LOG_DEBUG("trust ip=%s", ip);
			trustIpSet.insert(ip);
			addr = addr->NextSiblingElement();
		}
	}

	return 0;
}

// test mysqlmgr
int test1()
{
	std::string host = "127.0.0.1";
	int port = 3306;
	std::string username = "testss";
	std::string password = "123456";
	std::string db_name = "testss";

	MysqlMgr mgr;
	int ret = mgr.Connect(host, port, username, password, db_name);
	if (ret != 0)
	{
		LOG_ERROR("connect fail %d", ret);
		return -1;
	}

	// create
	LOG_DEBUG("******* create user_info");
	const char *sql = "CREATE TABLE IF NOT EXISTS `user_info` (\
		`user_id` bigint(20) NOT NULL AUTO_INCREMENT,\
		`channel_id` int(11) NOT NULL DEFAULT '0',\
		`username` varchar(45) NOT NULL UNIQUE,\
		`password` varchar(45) NOT NULL DEFAULT '',\
		`create_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,\
		PRIMARY KEY (`user_id`),\
		KEY `channel_id` (`channel_id`)\
	) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("create table user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}

	LOG_DEBUG("******* create user_role");
	sql = "CREATE TABLE IF NOT EXISTS `user_role` (\
		`role_id` bigint(20) NOT NULL AUTO_INCREMENT,\
		`user_id` bigint(20) NOT NULL,\
		`area_id` int(11) NOT NULL,\
		`role_name` varchar(45) NOT NULL,\
		PRIMARY KEY (`role_id`),\
		KEY `user_id` (`user_id`)\
	) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("create table user_role fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	LOG_DEBUG("");

	
	// insert 1 user
	LOG_DEBUG("******* insert user_info");
	sql = "INSERT INTO user_info (channel_id, username, password) VALUES (1, 'm1', '123456')";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 1)
	{
		LOG_ERROR("insert user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	LOG_DEBUG("affected rows %d", ret);
	LOG_DEBUG("");

	// insert 2 user
	LOG_DEBUG("******* insert user_info 2");
	sql = "INSERT INTO user_info (channel_id, username, password) VALUES (1, 'm2', '123456'), (1, 'm3', '123456')";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 2)
	{
		LOG_ERROR("insert user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	LOG_DEBUG("affected rows %d", ret);
	LOG_DEBUG("");

	// duplicate insert, test error
	LOG_DEBUG("******* insert user_info duplicate");
	sql = "INSERT INTO user_info (channel_id, username, password) VALUES (1, 'm1', '123456')";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != -1)
	{
		LOG_ERROR("insert duplicate fail %d", ret);
		return -1;
	}
	LOG_DEBUG("normal error insert duplicate affected rows %d", ret);
	LOG_DEBUG("normal errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
	LOG_DEBUG("");

	// select user
	{
	LOG_DEBUG("******* select user_info");
	sql = "SELECT * FROM user_info WHERE user_id = 1000";
	ret = mgr.Select(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("select user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	int fieldCount = mgr.FieldCount();
	int numRows = mgr.NumRows();
	LOG_DEBUG("fieldCount=%d numRows=%d", fieldCount, numRows);

	MYSQL_FIELD *pField = mgr.FetchField();
	MYSQL_ROW row;
	while ((row = mgr.FetchRow()) != NULL)
	{
		std::string buffer = "";
		for (int j = 0; j < fieldCount; j++)
		{
			buffer += std::string(pField[j].name) + std::string("=") + std::string(row[j]) + std::string(" ");
		}
		LOG_DEBUG("%s", buffer.c_str());
	}
	LOG_DEBUG("");
	}

	// select multi-user
	{
	LOG_DEBUG("******* select user_info 2");
	sql = "SELECT user_id, channel_id, username, password FROM user_info WHERE channel_id = 1";
	ret = mgr.Select(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("select user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	int fieldCount = mgr.FieldCount();
	int numRows = mgr.NumRows();
	LOG_DEBUG("fieldCount=%d numRows=%d", fieldCount, numRows);

	MYSQL_FIELD *pField = mgr.FetchField();
	MYSQL_ROW row;
	while ((row = mgr.FetchRow()) != NULL)
	{
		std::string buffer = "";
		for (int j = 0; j < fieldCount; j++)
		{
			buffer += std::string(pField[j].name) + std::string("=") + std::string(row[j]) + std::string(" ");
		}
		LOG_DEBUG("%s", buffer.c_str());
	}
	LOG_DEBUG("");
	}

	// update
	{
	LOG_DEBUG("******* update user_info");
	sql = "UPDATE `user_info` SET password='qwerty' WHERE username = 'm1'";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 1)
	{
		LOG_ERROR("update user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	}

	/*
	// delete
	sql = "DELETE FROM `user_info` where username IN ('m1', 'm2', 'm3')";
	ret = mgr.Change(sql, strlen(sql));
	if (ret < 0)
	{
		LOG_ERROR("delete user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	*/

	// drop
	sql = "DROP TABLE IF EXISTS `user_info`";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("drop table user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	
	sql = "DROP TABLE IF EXISTS `user_role`";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("drop table user_role fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}

	mgr.Close();

	return 0;
}

#ifdef _SINGLE_THREAD_CORE
int test2()
{
	return 0;
}

#else

void thread_run(EventPipe *pipe, bool isBlockWait)
{
	while (true)
	{
		const std::list<EventNode *> &node_list = pipe->Pop();
		for (auto iter = node_list.begin(); iter != node_list.end(); iter++)
		{
			const EventNode &node = **iter;
			LOG_DEBUG("node.type=%d", node.type);
			switch (node.type)
			{
				case EVENT_TYPE::EVENT_TYPE_NEW_CONNECTION:
				{
					const EventNodeNewConnection &real_node = (EventNodeNewConnection&)node;
					LOG_DEBUG("mailboxId=%ld connType=%d", real_node.mailboxId, real_node.connType);
					break;
				}
				case EVENT_TYPE::EVENT_TYPE_CONNNECT_TO_SUCCESS:
				{
					const EventNodeConnectToSuccess &real_node = (EventNodeConnectToSuccess&)node;
					LOG_DEBUG("mailboxId=%ld", real_node.mailboxId);
					break;
				}
				case EVENT_TYPE::EVENT_TYPE_DISCONNECT:
				{
					const EventNodeDisconnect &real_node = (EventNodeDisconnect&)node;
					LOG_DEBUG("mailboxId=%ld", real_node.mailboxId);
					break;
				}
				case EVENT_TYPE::EVENT_TYPE_TIMER:
				{
					// const EventNodeTimer &real_node = (EventNodeTimer&)node;
					break;
				}
				case EVENT_TYPE::EVENT_TYPE_MSG:
				{
					// const EventNodeMsg &real_node = (EventNodeMsg&)node;
					break;
				}
				case EVENT_TYPE::EVENT_TYPE_STDIN:
				{
					// const EventNodeStdin &real_node = (EventNodeStdin&)node;
					break;
				}
			}

			delete *iter;
		}

		if (!isBlockWait)
		{
			LOG_DEBUG("not block wait");
			sleep_second(1);
		}
	}
}

// test event_pipe
int test2()
{
	bool isBlockWait = true;
	EventPipe *pipe = new EventPipe(isBlockWait);

	std::thread t = std::thread(thread_run, pipe, isBlockWait);

	const int MAX_BUFFER = 100;
	char buffer[MAX_BUFFER+1] = {0};
	while (fgets(buffer, MAX_BUFFER, stdin))
	{
		{
			EventNodeNewConnection *node = new EventNodeNewConnection;
			node->mailboxId = 1;
			node->connType = E_CONN_TYPE::CONN_TYPE_TRUST;
			pipe->Push(node);
		}
		{
			EventNodeConnectToSuccess *node = new EventNodeConnectToSuccess;
			node->mailboxId = 2;
			pipe->Push(node);
		}
		{
			EventNodeDisconnect *node = new EventNodeDisconnect;
			node->mailboxId = 3;
			pipe->Push(node);
		}
		{
			EventNodeTimer *node = new EventNodeTimer;
			pipe->Push(node);
		}
		{
			EventNodeMsg *node = new EventNodeMsg;
			pipe->Push(node);
		}
		{
			EventNodeStdin *node = new EventNodeStdin;
			pipe->Push(node);
		}

	}

	return 0;
}
#endif

typedef int (*testcase_t) ();
testcase_t test_list[] =
{
	test0
,	test1
,	test2
};

int main(int argc, char ** argv)
{
	LOG_DEBUG("%s", argv[0]);

	int ret;
	int maxcase;
	int testcase;

	maxcase = sizeof(test_list) / sizeof(testcase_t);
	testcase = maxcase - 1;

	if (argc > 1) {
		if (!strcmp(argv[1], "all"))
		{
			LOG_DEBUG("run all case");
			for (int i=0; i<maxcase; i++)
			{
				printf("\n");
				LOG_DEBUG("run case[%d]", i);
				ret = test_list[i]();
				if (ret != 0) 
				{
					LOG_ERROR("case[%d] ret=%d", i, ret);
					return 0;
				}
			}
			return 0;
		}
		testcase = atoi(argv[1]);
		if (testcase < 0 || testcase >= maxcase) 
		{
			testcase = maxcase - 1;
		}
	}

	LOG_DEBUG("run case[%d]", testcase);
	ret = test_list[testcase]();
	if (ret != 0) 
	{
		LOG_ERROR("case[%d] ret=%d", testcase, ret);
	}

	return 0;
}
