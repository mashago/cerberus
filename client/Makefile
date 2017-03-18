default: platform client_test

OS:=$(shell uname -s)

CXXFLAG:=-g -Wall -std=c++0x
LIB:=-levent

platform:
	@echo Platform: $(OS)

clean:
	rm -rf client_test
	rm -rf *.dSYM

client_test: client_test.cpp 
	g++ $(CXXFLAG) -o $@ $< $(LIB)
