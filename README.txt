# A Simple Game Server Framework

Description:
build by C++ & Lua, config use XML
all server is single thread for now

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

