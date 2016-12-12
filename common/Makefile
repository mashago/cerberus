default: platform net_server.o libcommon.a 

OS:=$(shell uname -s)

CFLAG:=-Wall -g

platform:
	@echo Platform: $(OS)

clean:
	rm -rf net_server.o
	rm -rf ../lib/libcommon.a
	rm -rf *.dSYM

net_server.o: net_server.cpp 
	g++ -c -o $@ $^

libcommon.a: net_server.o
	ar -crus ../lib/$@ $^

