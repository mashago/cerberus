-- call by root

CREATE DATABASE IF NOT EXISTS mn_game_db1;
GRANT all on mn_game_db1.* to testmn@'%' identified by '123456';
GRANT all on mn_game_db1.* to testmn@'localhost' identified by '123456';
