default: platform main 

OS:=$(shell uname -s)

CXXFLAG:=-Wall -g
INC:=../common
LIB_PATH:=../lib
LIB:=-lcommon -levent

platform:
	@echo Platform: $(OS)

clean:
	rm -rf main
	rm -rf *.dSYM

main: main.cpp 
	g++ $(CXXFLAG) -o $@ $< -I $(INC) -L $(LIB_PATH) $(LIB)

