# A Simple Game Server Framework

Description:
build by C++ & Lua, config use XML
network and logicworld run in different thread

View:

     Client
    /       \
   /          \
  |             \
  v              v
Login           Router(n)
  | ^         ^  ^    ^ 
  |  \       /    \    \
  |   \     /      \     \
  v    \   /        \      \
 DB(n) Bridge      Scene1  Scene2(n) ....
                      \        /
                       \      /
                        v    v
                         DB(n)

Global Public Server:
1 * Login
n * Login DB

What One Server Package Has:
1 * Bridge
n * Router
n * Scene
n * DB
......

TODO:
rpc timeout check

