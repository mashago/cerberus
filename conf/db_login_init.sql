-- call by root
CREATE DATABASE IF NOT EXISTS mn_login_db;
GRANT all on mn_login_db.* to testmn@'%' identified by '123456';
GRANT all on mn_login_db.* to testmn@'localhost' identified by '123456';

USE mn_login_db;
-- DROP TABLE IF EXISTS `user_info`;
CREATE TABLE IF NOT EXISTS `user_info` (
	`user_id` bigint(20) NOT NULL AUTO_INCREMENT,
	`channel_id` int(11) NOT NULL DEFAULT '0',
	`username` varchar(45) NOT NULL,
	`password` varchar(45) NOT NULL DEFAULT '',
	`create_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`user_id`),
	UNIQUE KEY `username` (`username`),
	KEY `channel_id` (`channel_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8;

-- DROP TABLE IF EXISTS `user_role`;
CREATE TABLE IF NOT EXISTS `user_role` (
	`role_id` bigint(20) NOT NULL AUTO_INCREMENT,
	`user_id` bigint(20) NOT NULL,
	`area_id` int(11) NOT NULL,
	`role_name` varchar(45) NOT NULL,
	`is_delete` int(11) NOT NULL DEFAULT '0',
	PRIMARY KEY (`role_id`),
	UNIQUE KEY `role_name` (`role_name`),
	KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10000 DEFAULT CHARSET=utf8;

-- create role procedure
DROP PROCEDURE IF EXISTS `create_user_role`;
DELIMITER ;;
CREATE PROCEDURE `create_user_role`(
IN in_user_id BIGINT(20),
IN in_area_id INT,
IN in_role_name VARCHAR(45),
IN in_max_role INT
)
BEGIN
	DECLARE out_role_id BIGINT(64);
	DECLARE out_role_count INT;
	DECLARE EXIT HANDLER FOR 1062 SELECT -2 AS role_id; -- handle duplicate role_name 
	
	SELECT COUNT(*) INTO out_role_count FROM `user_role` WHERE `user_id`=in_user_id AND `area_id`=in_area_id AND `is_delete`=0;

	IF out_role_count >= in_max_role THEN
		SELECT -1 AS role_id;
	ELSE
		INSERT INTO `user_role`(`user_id`,`area_id`,`role_name`) VALUES (in_user_id,in_area_id,in_role_name);
		SELECT LAST_INSERT_ID() AS role_id;
	END IF;
END ;;
DELIMITER ;
