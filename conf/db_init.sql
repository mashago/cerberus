-- call by root
CREATE DATABASE IF NOT EXISTS login_db;
GRANT all on login_db.* to testss@'%' identified by '123456';
GRANT all on login_db.* to testss@'localhost' identified by '123456';

CREATE DATABASE IF NOT EXISTS game_db;
GRANT all on game_db.* to testss@'%' identified by '123456';
GRANT all on game_db.* to testss@'localhost' identified by '123456';

use login_db;
DROP TABLE IF EXISTS `user_info`;
CREATE TABLE IF NOT EXISTS `user_info` (
	`user_id` bigint(20) NOT NULL AUTO_INCREMENT,
	`channel_id` int(11) NOT NULL DEFAULT '0',
	`username` varchar(45) NOT NULL UNIQUE,
	`password` varchar(45) NOT NULL DEFAULT '',
	`create_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`user_id`),
	KEY `channel_id` (`channel_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8;
